-- AlterTable
ALTER TABLE "SignalProfile" ADD COLUMN     "sessionId" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "SignalProfile_studentId_sessionId_key" ON "SignalProfile"("studentId", "sessionId");

