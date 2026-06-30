-- Allow a vehicle to exist without a garage (driver not attached to any garage).
-- Drop the FK, make the column nullable, then re-create the FK as ON DELETE SET NULL.
ALTER TABLE "vehicles" DROP CONSTRAINT IF EXISTS "vehicles_garage_id_fkey";

ALTER TABLE "vehicles" ALTER COLUMN "garage_id" DROP NOT NULL;

ALTER TABLE "vehicles"
  ADD CONSTRAINT "vehicles_garage_id_fkey"
  FOREIGN KEY ("garage_id") REFERENCES "garages"("id") ON DELETE SET NULL ON UPDATE CASCADE;
