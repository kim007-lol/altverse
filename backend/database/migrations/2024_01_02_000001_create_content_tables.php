<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ─── Genres ───
        Schema::create('genres', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->timestamps();
        });

        // ─── Series (sebelumnya: aus) ───
        Schema::create('series', function (Blueprint $table) {
            $table->id();
            $table->foreignId('author_id')->constrained('users')->cascadeOnDelete();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('synopsis')->nullable();
            $table->string('genre')->nullable();
            $table->enum('age_rating', ['all', '13+', '17+', '18+'])->default('all');
            $table->string('cover_url')->nullable();
            $table->string('source_url')->nullable();
            $table->enum('status', ['draft', 'published', 'archived'])->default('draft');
            $table->boolean('is_premium')->default(false);
            $table->unsignedBigInteger('total_views')->default(0);
            $table->unsignedBigInteger('total_likes')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->index('author_id');
            $table->index('status');
        });

        // ─── Pivot: Series ↔ Genre ───
        Schema::create('genre_series', function (Blueprint $table) {
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->foreignId('genre_id')->constrained('genres')->cascadeOnDelete();
            $table->primary(['series_id', 'genre_id']);
        });

        // ─── Episodes (sebelumnya: chapters) ───
        Schema::create('episodes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('series_id')->constrained('series')->cascadeOnDelete();
            $table->string('title');
            $table->unsignedInteger('episode_number')->default(1);
            $table->string('cover_url')->nullable();
            $table->string('thumbnail_url')->nullable();
            $table->boolean('is_premium')->default(false);
            $table->unsignedInteger('coin_price')->default(0);
            $table->unsignedBigInteger('view_count')->default(0);
            $table->enum('status', ['draft', 'scheduled', 'published'])->default('draft');
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('published_at')->nullable();
            $table->timestamps();

            $table->index(['series_id', 'episode_number']);
        });

        // ─── Pages (sebelumnya: chapter_images, max 100 per episode) ───
        Schema::create('pages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('episode_id')->constrained('episodes')->cascadeOnDelete();
            $table->string('image_path'); // R2/S3 object path
            $table->unsignedInteger('page_order')->default(1);
            $table->unsignedInteger('width')->nullable();
            $table->unsignedInteger('height')->nullable();
            $table->unsignedInteger('file_size')->nullable(); // bytes
            $table->timestamps();

            $table->index(['episode_id', 'page_order']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pages');
        Schema::dropIfExists('episodes');
        Schema::dropIfExists('genre_series');
        Schema::dropIfExists('series');
        Schema::dropIfExists('genres');
    }
};
