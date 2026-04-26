<?php

namespace App\Services;

use App\Models\Mission;
use App\Models\UserMission;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class MissionService
{
    /**
     * Get all missions with user progress
     */
    public function getUserMissions(User $user): array
    {
        $missions = Mission::active()->get();
        $today = now()->toDateString();
        $weekStart = now()->startOfWeek()->toDateString();

        return $missions->map(function ($mission) use ($user, $today, $weekStart) {
            $userMission = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->first();

            // Check if need to reset progress
            $needsReset = false;
            if ($userMission) {
                if ($mission->isDaily() && $userMission->updated_at->toDateString() !== $today) {
                    $needsReset = true;
                } elseif ($mission->isWeekly() && $userMission->updated_at->toDateString() < $weekStart) {
                    $needsReset = true;
                }
            }

            if ($needsReset) {
                $userMission->update(['progress' => 0, 'completed_at' => null, 'claimed_at' => null]);
                $userMission->refresh();
            }

            $progress = $userMission->progress ?? 0;
            $isCompleted = $userMission && $userMission->completed_at !== null;
            $isClaimed = $userMission && $userMission->claimed_at !== null;
            $canClaim = $isCompleted && !$isClaimed;

            return [
                'id' => $mission->id,
                'code' => $mission->code,
                'name' => $mission->name,
                'description' => $mission->description,
                'type' => $mission->type,
                'xp_reward' => $mission->xp_reward,
                'coin_reward' => $mission->coin_reward,
                'target_count' => $mission->target_count,
                'progress' => $progress,
                'is_completed' => $isCompleted,
                'is_claimed' => $isClaimed,
                'can_claim' => $canClaim,
                'completed_at' => $userMission->completed_at ?? null,
                'claimed_at' => $userMission->claimed_at ?? null,
            ];
        })->toArray();
    }

    /**
     * Track mission progress
     */
    public function trackProgress(User $user, string $missionCode, int $increment = 1): bool
    {
        $mission = Mission::where('code', $missionCode)->active()->first();
        if (!$mission) return false;

        return DB::transaction(function () use ($user, $mission, $increment) {
            $userMission = UserMission::firstOrCreate(
                [
                    'user_id' => $user->id,
                    'mission_id' => $mission->id,
                ],
                ['progress' => 0]
            );

            // Check if already completed and claimed (for once type)
            if ($mission->isOnce() && $userMission->claimed_at) {
                return false;
            }

            // Check if need to reset
            $today = now()->toDateString();
            $weekStart = now()->startOfWeek()->toDateString();
            
            if ($mission->isDaily() && $userMission->updated_at->toDateString() !== $today) {
                $userMission->update(['progress' => 0, 'completed_at' => null, 'claimed_at' => null]);
            } elseif ($mission->isWeekly() && $userMission->updated_at->toDateString() < $weekStart) {
                $userMission->update(['progress' => 0, 'completed_at' => null, 'claimed_at' => null]);
            }

            $userMission->refresh();

            // Increment progress
            $newProgress = min($userMission->progress + $increment, $mission->target_count);
            $userMission->update(['progress' => $newProgress]);

            // Mark as completed if target reached
            if ($newProgress >= $mission->target_count && !$userMission->completed_at) {
                $userMission->update(['completed_at' => now()]);
            }

            return true;
        });
    }

    /**
     * Claim mission reward
     */
    public function claimReward(User $user, int $missionId): array
    {
        $mission = Mission::find($missionId);
        if (!$mission) {
            return ['success' => false, 'message' => 'Mission not found'];
        }

        return DB::transaction(function () use ($user, $mission) {
            $userMission = UserMission::where('user_id', $user->id)
                ->where('mission_id', $mission->id)
                ->lockForUpdate()
                ->first();

            if (!$userMission || !$userMission->completed_at) {
                return ['success' => false, 'message' => 'Mission not completed'];
            }

            if ($userMission->claimed_at) {
                return ['success' => false, 'message' => 'Reward already claimed'];
            }

            // Award XP
            if ($mission->xp_reward > 0) {
                XpService::award($user->id, 'mission_complete');
                
                // Manual XP addition for mission reward
                $xpRecord = \App\Models\UserXp::firstOrCreate(
                    ['user_id' => $user->id],
                    ['total_xp' => 0, 'level' => 0]
                );
                $xpRecord->increment('total_xp', $mission->xp_reward);
                $xpRecord->refresh();
                
                $newLevel = \App\Models\UserXp::calculateLevel($xpRecord->total_xp);
                if ($xpRecord->level !== $newLevel) {
                    $xpRecord->update(['level' => $newLevel]);
                }
            }

            // Award coins
            if ($mission->coin_reward > 0) {
                $user->increment('coins', $mission->coin_reward);
                
                // Log transaction
                \App\Models\Transaction::create([
                    'user_id' => $user->id,
                    'type' => 'mission_reward',
                    'amount' => $mission->coin_reward,
                    'description' => "Mission reward: {$mission->name}",
                ]);
            }

            // Mark as claimed
            $userMission->update(['claimed_at' => now()]);

            return [
                'success' => true,
                'message' => 'Reward claimed successfully',
                'data' => [
                    'xp_reward' => $mission->xp_reward,
                    'coin_reward' => $mission->coin_reward,
                ],
            ];
        });
    }

    /**
     * Auto-track mission progress based on activity
     */
    public function autoTrack(User $user, string $activity): void
    {
        $missionMap = [
            'login' => 'daily_login',
            'read_episode' => 'daily_read_5',
            'comment' => 'daily_comment_3',
            'like_episode' => 'daily_like_5',
            'follow' => 'weekly_follow_5',
            'bookmark' => 'weekly_bookmark_5',
        ];

        if (isset($missionMap[$activity])) {
            $this->trackProgress($user, $missionMap[$activity]);
        }

        // Track weekly read mission
        if ($activity === 'read_episode') {
            $this->trackProgress($user, 'weekly_read_25');
        }

        // Track weekly comment mission
        if ($activity === 'comment') {
            $this->trackProgress($user, 'weekly_comment_15');
        }

        // Track one-time missions
        $this->trackOnceMissions($user, $activity);
    }

    /**
     * Track one-time achievement missions
     */
    private function trackOnceMissions(User $user, string $activity): void
    {
        switch ($activity) {
            case 'read_episode':
                // Check total reads
                $totalReads = \App\Models\ReadingHistory::where('user_id', $user->id)
                    ->where('progress', '>=', 100)
                    ->count();
                
                if ($totalReads >= 100) {
                    $this->trackProgress($user, 'read_100_episodes', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'read_100_episodes'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 100, 'completed_at' => now()]);
                    }
                }
                if ($totalReads >= 500) {
                    $this->trackProgress($user, 'read_500_episodes', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'read_500_episodes'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 500, 'completed_at' => now()]);
                    }
                }
                if ($totalReads >= 1000) {
                    $this->trackProgress($user, 'read_1000_episodes', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'read_1000_episodes'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 1000, 'completed_at' => now()]);
                    }
                }
                break;

            case 'comment':
                $totalComments = \App\Models\Comment::where('user_id', $user->id)->count();
                if ($totalComments >= 100) {
                    $this->trackProgress($user, 'comment_100', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'comment_100'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 100, 'completed_at' => now()]);
                    }
                }
                break;

            case 'follow':
                $totalFollows = \App\Models\User::find($user->id)->following()->count();
                if ($totalFollows >= 50) {
                    $this->trackProgress($user, 'follow_50_authors', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'follow_50_authors'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 50, 'completed_at' => now()]);
                    }
                }
                break;

            case 'bookmark':
                $totalBookmarks = \App\Models\Bookmark::where('user_id', $user->id)->count();
                if ($totalBookmarks >= 50) {
                    $this->trackProgress($user, 'bookmark_50_series', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'bookmark_50_series'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 50, 'completed_at' => now()]);
                    }
                }
                break;

            case 'spend_coins':
                $totalSpend = $user->lifetime_spend ?? 0;
                if ($totalSpend >= 500) {
                    $this->trackProgress($user, 'spend_500_coins', 0);
                    $mission = UserMission::where('user_id', $user->id)
                        ->whereHas('mission', fn($q) => $q->where('code', 'spend_500_coins'))
                        ->first();
                    if ($mission && !$mission->completed_at) {
                        $mission->update(['progress' => 500, 'completed_at' => now()]);
                    }
                }
                break;
        }
    }
}
