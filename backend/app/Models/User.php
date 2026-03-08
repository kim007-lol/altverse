<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'avatar_url',
        'author_avatar_url',
        'pen_name',
        'bio',
        'author_bio',
        'social_links',
        'theme_preference',
    ];

    /**
     * Sensitive fields — must never be mass-assignable.
     * These are only modified through explicit, controlled code paths.
     */
    protected $guarded_manual = [
        'role',
        'coins',
        'level',
        'exp_points',
        'lifetime_spend',
        'supporter_level_id',
        'author_tier',
        'followers_count',
        'total_views',
        'published_episode_count',
        'can_customize_banner',
        'can_tip',
        'is_verified',
        'tier_updated_at',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'social_links' => 'array',
        ];
    }

    // ─── Relationships ───

    public function isAuthor(): bool
    {
        return $this->role === 'author';
    }

    public function isReader(): bool
    {
        return $this->role === 'reader';
    }

    /** Series milik Author */
    public function series()
    {
        return $this->hasMany(Series::class, 'author_id');
    }

    /** Bookmarks Reader */
    public function bookmarks()
    {
        return $this->belongsToMany(Series::class, 'bookmarks')->withTimestamps();
    }

    /** Likes Reader */
    public function likes()
    {
        return $this->belongsToMany(Series::class, 'likes')->withTimestamps();
    }

    /** Following (Reader → Author) */
    public function following()
    {
        return $this->belongsToMany(User::class, 'follows', 'follower_id', 'following_id')->withTimestamps();
    }

    /** Followers (Author ← Reader) */
    public function followers()
    {
        return $this->belongsToMany(User::class, 'follows', 'following_id', 'follower_id')->withTimestamps();
    }

    /** Reading history */
    public function readingHistories()
    {
        return $this->hasMany(ReadingHistory::class);
    }

    /** Collections / Playlists */
    public function collections()
    {
        return $this->hasMany(Collection::class);
    }

    /** Transactions (wallet) */
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    /** Badges earned */
    public function badges()
    {
        return $this->belongsToMany(Badge::class, 'badge_user')->withPivot('earned_at');
    }

    /** Genre preferences */
    public function genrePreferences()
    {
        return $this->belongsToMany(Genre::class, 'genre_preferences')->withPivot('weight')->withTimestamps();
    }

    /** Blocked users */
    public function blockedUsers()
    {
        return $this->belongsToMany(User::class, 'blocked_users', 'user_id', 'blocked_user_id')->withTimestamps();
    }

    /** Unlocked premium episodes */
    public function unlockedEpisodes()
    {
        return $this->belongsToMany(Episode::class, 'user_episode_unlocks')
            ->withPivot('unlock_type')
            ->withTimestamps();
    }

    /** Check if user has access to an episode */
    public function hasEpisodeAccess(Episode $episode): bool
    {
        if (!$episode->is_premium) {
            return true;
        }

        // Author of the series always has access
        if ($episode->series->author_id === $this->id) {
            return true;
        }

        // Individual unlock
        return $this->unlockedEpisodes()
            ->where('episode_id', $episode->id)
            ->exists();
    }

    // ─── Gamification relationships ───

    /** Supporter tier (permanent badge) */
    public function supporterLevel()
    {
        return $this->belongsTo(SupporterLevel::class);
    }

    /** XP record */
    public function xp()
    {
        return $this->hasOne(UserXp::class);
    }

    /** Global season rankings */
    public function seasonGlobal()
    {
        return $this->hasMany(UserSeasonGlobal::class);
    }

    /** Per-author season rankings */
    public function seasonAuthor()
    {
        return $this->hasMany(UserSeasonAuthor::class);
    }

    /** Lifetime support totals per author */
    public function authorSupportGiven()
    {
        return $this->hasMany(AuthorSupportTotal::class);
    }

    /** Support received (as author) */
    public function authorSupportReceived()
    {
        return $this->hasMany(AuthorSupportTotal::class, 'author_id');
    }

    /** Season supporter stats (coins spent per season) */
    public function seasonSupporter()
    {
        return $this->hasMany(SeasonSupporter::class);
    }

    /** Season author earning stats (coins earned per season, as author) */
    public function seasonAuthorEarnings()
    {
        return $this->hasMany(SeasonAuthorEarning::class, 'author_id');
    }
}
