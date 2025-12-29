-- CreateEnum
CREATE TYPE "GuardianStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED');

-- CreateEnum
CREATE TYPE "TripStatus" AS ENUM ('ACTIVE', 'COMPLETED_SAFE', 'TIMED_OUT', 'DURESS_ENDED', 'PANIC_ENDED');

-- CreateEnum
CREATE TYPE "AlertType" AS ENUM ('TIMEOUT', 'PANIC_BUTTON', 'DURESS_PIN');

-- CreateTable
CREATE TABLE "users" (
    "user_id" SERIAL NOT NULL,
    "phone_number" VARCHAR(20) NOT NULL,
    "full_name" VARCHAR(100) NOT NULL,
    "email" VARCHAR(100),
    "avatar_url" VARCHAR(255),
    "password_hash" VARCHAR(255) NOT NULL,
    "safe_pin_hash" VARCHAR(255) NOT NULL,
    "duress_pin_hash" VARCHAR(255) NOT NULL,
    "last_known_lat" DECIMAL(10,8),
    "last_known_lng" DECIMAL(11,8),
    "last_battery_level" SMALLINT,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "guardians" (
    "guardian_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "guardian_name" VARCHAR(100) NOT NULL,
    "guardian_phone" VARCHAR(20) NOT NULL,
    "relationship" VARCHAR(50),
    "status" "GuardianStatus" NOT NULL DEFAULT 'PENDING',

    CONSTRAINT "guardians_pkey" PRIMARY KEY ("guardian_id")
);

-- CreateTable
CREATE TABLE "trips" (
    "trip_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "destination_name" TEXT,
    "destination_lat" DECIMAL(10,8),
    "destination_lng" DECIMAL(11,8),
    "expected_duration_minutes" INTEGER NOT NULL,
    "expected_end_time" TIMESTAMP NOT NULL,
    "status" "TripStatus" NOT NULL DEFAULT 'ACTIVE',

    CONSTRAINT "trips_pkey" PRIMARY KEY ("trip_id")
);

-- CreateTable
CREATE TABLE "trip_locations" (
    "log_id" BIGSERIAL NOT NULL,
    "trip_id" INTEGER NOT NULL,
    "lat" DECIMAL(10,8) NOT NULL,
    "lng" DECIMAL(11,8) NOT NULL,
    "recorded_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "trip_locations_pkey" PRIMARY KEY ("log_id")
);

-- CreateTable
CREATE TABLE "alerts" (
    "alert_id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "trip_id" INTEGER,
    "alert_type" "AlertType" NOT NULL,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "alerts_pkey" PRIMARY KEY ("alert_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_phone_number_key" ON "users"("phone_number");

-- CreateIndex
CREATE UNIQUE INDEX "guardians_user_id_guardian_phone_key" ON "guardians"("user_id", "guardian_phone");

-- AddForeignKey
ALTER TABLE "guardians" ADD CONSTRAINT "guardians_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trips" ADD CONSTRAINT "trips_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "trip_locations" ADD CONSTRAINT "trip_locations_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("trip_id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "alerts" ADD CONSTRAINT "alerts_trip_id_fkey" FOREIGN KEY ("trip_id") REFERENCES "trips"("trip_id") ON DELETE SET NULL ON UPDATE CASCADE;
