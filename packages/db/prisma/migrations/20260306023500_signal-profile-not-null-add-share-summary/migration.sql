-- AlterTable
ALTER TABLE "SignalProfile" ALTER COLUMN "sessionId" SET NOT NULL;

-- AlterTable
ALTER TABLE "StudentPrivacySettings" ADD COLUMN     "shareSummary" BOOLEAN NOT NULL DEFAULT true;

