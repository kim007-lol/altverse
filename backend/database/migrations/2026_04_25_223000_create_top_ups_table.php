<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('top_ups', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('order_id')->unique();                  // Midtrans order_id
            $table->string('package_id');                          // pkg_basic, etc.
            $table->integer('amount_idr');                         // Harga dalam Rupiah
            $table->integer('coins');                              // Jumlah coin yang didapat
            $table->enum('status', ['pending', 'paid', 'failed', 'expired'])->default('pending');
            $table->string('midtrans_transaction_id')->nullable(); // Midtrans transaction ID
            $table->string('payment_type')->nullable();            // qris, bank_transfer, etc.
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('top_ups');
    }
};
