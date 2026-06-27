/*
  Warnings:

  - Changed the type of `type` on the `Kyc` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterTable
ALTER TABLE "Kyc" DROP COLUMN "type",
ADD COLUMN     "type" "UserRole" NOT NULL;

-- CreateIndex
CREATE INDEX "Kyc_userId_idx" ON "Kyc"("userId");
