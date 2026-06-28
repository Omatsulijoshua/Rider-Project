ALTER TYPE "DriverStatus" ADD VALUE IF NOT EXISTS 'ON_DELIVERY';

ALTER TABLE "Driver"
  ADD COLUMN IF NOT EXISTS "vehicleType" TEXT,
  ADD COLUMN IF NOT EXISTS "lastActiveAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "locationDisabledAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "fraudScore" INTEGER NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS "Driver_isOnline_status_idx" ON "Driver"("isOnline", "status");
CREATE INDEX IF NOT EXISTS "Driver_vehicleType_idx" ON "Driver"("vehicleType");
