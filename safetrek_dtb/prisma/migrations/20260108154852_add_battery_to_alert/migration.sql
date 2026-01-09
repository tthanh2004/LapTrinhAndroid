/*
  Warnings:

  - You are about to drop the column `last_battery_level` on the `users` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[email]` on the table `users` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "alerts" ADD COLUMN     "batteryLevel" INTEGER DEFAULT 0;

-- AlterTable
ALTER TABLE "users" DROP COLUMN "last_battery_level",
ADD COLUMN     "fcm_token" VARCHAR(255),
ALTER COLUMN "phone_number" DROP NOT NULL,
ALTER COLUMN "full_name" DROP NOT NULL,
ALTER COLUMN "password_hash" DROP NOT NULL,
ALTER COLUMN "safe_pin_hash" DROP NOT NULL,
ALTER COLUMN "duress_pin_hash" DROP NOT NULL;

-- CreateTable
CREATE TABLE "notifications" (
    "notification_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "body" TEXT NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "data" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("notification_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;
