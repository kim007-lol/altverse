<?php

namespace App\Services;

use App\Models\Mission;
use App\Models\UserMission;
use App\Models\UserXp;
use App\Models\UserSeasonGlobal;
use App\Models\Season;
use App\Models\ReadingHistory;
use App\Models\Comment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;

class MissionService
{
    /**
     * Get all active missions along with the user's progress.
     */
    public function getMissions(User $user)
    {
        $missions = Mission::where('is_active', true)->get();
        $today = now()->toDateString();

        return $missions->map(function ($mission) use ($user, $today) {
            $claimsToday = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->whereDate('created_at', $today)
                ->count();

            $lastClaim = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->latest()
                ->first();

            $isOnCooldown = false;
            if ($lastClaim && $mission->cooldown_seconds) {
                $isOnCooldown = $lastClaim->created_at->addSeconds($mission->cooldown_seconds)->isFuture();
            }

            return [
                'id' => $mission->id,
                'code' => $mission->code,
                'title' => $mission->title,
                'description' => $mission->description,
                'xp_reward' => $mission->xp_reward,
                'daily_limit' => $mission->daily_limit,
                'claims_today' => $claimsToday,
                'is_on_cooldown' => $isOnCooldown,
                'can_claim' => !$isOnCooldown && ($mission->daily_limit === null || $claimsToday < $mission->daily_limit),
            ];
        });
    }

    /**
     * Attempt to claim a mission.
     */
    public function claimMission(User $user, string $missionCode): array
    {
        $mission = Mission::where('code', $missionCode)->where('is_active', true)->first();

        if (!$mission) {
            return ['success' => false, 'message' => 'Misi tidak ditemukan atau tidak aktif.', 'code' => 404];
        }

        return DB::transaction(function () use ($user, $mission, $missionCode) {
            $today = now()->toDateString();

            // Pessimistic lock on UserXp to serialize concurrent claim attempts for the same user
            $record = UserXp::lockForUpdate()->firstOrCreate(
                ['user_id' => $user->id],
                ['total_xp' => 0, 'level' => 0]
            );

            $claimsToday = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->whereDate('created_at', $today)
                ->count();

            if ($mission->daily_limit !== null && $claimsToday >= $mission->daily_limit) {
                return ['success' => false, 'message' => 'Batas klaim harian untuk misi ini telah tercapai.', 'code' => 429];
            }

            $lastClaim = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->latest()
                ->first();

            if ($lastClaim && $mission->cooldown_seconds) {
                if ($lastClaim->created_at->addSeconds($mission->cooldown_seconds)->isFuture()) {
                    return ['success' => false, 'message' => 'Misi sedang dalam masa cooldown.', 'code' => 429];
                }
            }

            if (!$this->verifyMissionCompletion($user, $missionCode, $today, $claimsToday)) {
                return ['success' => false, 'message' => 'Syarat misi belum terpenuhi hari ini.', 'code' => 422];
            }

            // Log claim
            UserMission::create([
                'user_id' => $user->id,
                'mission_id' => $mission->id,
            ]);

            // Add XP
            $record->increment('total_xp', $mission->xp_reward);
            $record->refresh();

            $newLevel = UserXp::calculateLevel($record->total_xp);
            if ($record->level !== $newLevel) {
                $record->update(['level' => $newLevel]);
            }

            // Season global XP
            $season = Season::active()->first();
            if ($season) {
                UserSeasonGlobal::updateOrCreate(
                    ['user_id' => $user->id, 'season_id' => $season->id],
                    []
                )->increment('xp', $mission->xp_reward);

                // Clear cache only if season is active
                Cache::forget("leaderboard:xp:{$season->id}");
            }

            return [
                'success' => true,
                'message' => 'Misi berhasil diklaim!',
                'data' => [
                    'xp_awarded' => $mission->xp_reward,
                    'total_xp' => $record->total_xp,
                    'level' => $record->level,
                ],
                'code' => 200
            ];
        });
    }

    /**
     * Auto-claim a mission synchronously without throwing HTTP exceptions/status codes.
     */
    public function autoClaimMission(User $user, string $missionCode): bool
    {
        $mission = Mission::where('code', $missionCode)->where('is_active', true)->first();
        if (!$mission) return false;

        $today = now()->toDateString();

        try {
            return DB::transaction(function () use ($user, $mission, $missionCode, $today) {
                $record = UserXp::lockForUpdate()->firstOrCreate(
                    ['user_id' => $user->id],
                    ['total_xp' => 0, 'level' => 0]
                );

                $claimsToday = UserMission::where('user_id', $user->id)
                    ->where('mission_id', $mission->id)
                    ->whereDate('created_at', $today)
                    ->count();

                if ($mission->daily_limit !== null && $claimsToday >= $mission->daily_limit) {
                    return false;
                }

                $lastClaim = UserMission::where('user_id', $user->id)
                    ->where('mission_id', $mission->id)
                    ->latest()
                    ->first();

                if ($lastClaim && $mission->cooldown_seconds) {
                    if ($lastClaim->created_at->addSeconds($mission->cooldown_seconds)->isFuture()) {
                        return false;
                    }
                }

                if (!$this->verifyMissionCompletion($user, $missionCode, $today, $claimsToday)) {
                    return false;
                }

                UserMission::create([
                    'user_id' => $user->id,
                    'mission_id' => $mission->id,
                ]);

                $record->increment('total_xp', $mission->xp_reward);
                $newLevel = UserXp::calculateLevel($record->total_xp);
                if ($record->level !== $newLevel) {
                    $record->update(['level' => $newLevel]);
                }

                $season = Season::active()->first();
                if ($season) {
                    UserSeasonGlobal::updateOrCreate(
                        ['user_id' => $user->id, 'season_id' => $season->id],
                        []
                    )->increment('xp', $mission->xp_reward);
                    Cache::forget("leaderboard:xp:{$season->id}");
                }

                return true;
            });
        } catch (\Exception $e) {
            return false;
        }
    }

    /**
     * Logic to verify if the user actually did the mission.
     */
    private function verifyMissionCompletion(User $user, string $code, string $today, int $claimsToday): bool
    {
        return match ($code) {
            'read_episode' => ReadingHistory::where('user_id', $user->id)->whereDate('read_at', $today)->where('progress', '>=', 100)->count() > $claimsToday,
            'post_comment' => Comment::where('user_id', $user->id)->whereDate('created_at', $today)->count() > $claimsToday,
            default => false,
        };
    }
}
