-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql" VERSION "1.5.11";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions" VERSION "1.11";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions" VERSION "1.3";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog" VERSION "1.0";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault" VERSION "0.3.1";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions" VERSION "1.1";

-- CreateExtension
CREATE EXTENSION IF NOT EXISTS "vector" WITH SCHEMA "public" VERSION "0.8.0";

-- CreateEnum
CREATE TYPE "public"."ActivityCategory" AS ENUM ('ACADEMIC', 'EXTRACURRICULAR', 'READING', 'PROJECT', 'WORK', 'VOLUNTEER', 'HOBBY');

-- CreateEnum
CREATE TYPE "public"."EdgeType" AS ENUM ('REQUIRES', 'LEADS_TO', 'RELATED', 'ALTERNATIVE');

-- CreateEnum
CREATE TYPE "public"."MapNodeType" AS ENUM ('CAREER', 'MAJOR', 'INDUSTRY', 'PROGRAM', 'SKILL', 'VALUE');

-- CreateEnum
CREATE TYPE "public"."NotificationType" AS ENUM ('REFLECTION_NUDGE', 'OPPORTUNITY', 'MAP_EXPANSION', 'PEER_PROMPT');

-- CreateEnum
CREATE TYPE "public"."PromptType" AS ENUM ('PATTERN', 'EXPLORATION', 'IDENTITY', 'CHALLENGE');

-- CreateEnum
CREATE TYPE "public"."Role" AS ENUM ('STUDENT', 'COUNSELOR', 'ADMIN');

-- CreateTable
CREATE TABLE "public"."Activity" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "sessionId" TEXT,
    "category" "public"."ActivityCategory" NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "hoursPerWeek" DECIMAL(65,30),
    "excitement" INTEGER,
    "isOngoing" BOOLEAN NOT NULL DEFAULT true,
    "startDate" TIMESTAMP(3),
    "endDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Activity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Counselor" (
    "id" TEXT NOT NULL,
    "clerkId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "schoolId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Counselor_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."MapEdge" (
    "id" TEXT NOT NULL,
    "sourceId" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    "edgeType" "public"."EdgeType" NOT NULL DEFAULT 'RELATED',

    CONSTRAINT "MapEdge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."MapNode" (
    "id" TEXT NOT NULL,
    "type" "public"."MapNodeType" NOT NULL,
    "label" TEXT NOT NULL,
    "description" TEXT,
    "metadata" JSONB NOT NULL DEFAULT '{}',
    "parentId" TEXT,
    "embedding" vector(1024),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MapNode_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Notification" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "type" "public"."NotificationType" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "relatedNodeId" TEXT,
    "deliveredAt" TIMESTAMP(3),
    "readAt" TIMESTAMP(3),
    "actedOn" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."NotificationPreferences" (
    "studentId" TEXT NOT NULL,
    "maxPerWeek" INTEGER NOT NULL DEFAULT 3,
    "reflectionNudges" BOOLEAN NOT NULL DEFAULT true,
    "opportunityAlerts" BOOLEAN NOT NULL DEFAULT true,
    "mapExpansions" BOOLEAN NOT NULL DEFAULT true,
    "peerPrompts" BOOLEAN NOT NULL DEFAULT true,
    "quietHoursStart" TEXT NOT NULL DEFAULT '21:00',
    "quietHoursEnd" TEXT NOT NULL DEFAULT '08:00',

    CONSTRAINT "NotificationPreferences_pkey" PRIMARY KEY ("studentId")
);

-- CreateTable
CREATE TABLE "public"."PeerGroup" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "formedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PeerGroup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."PeerGroupMember" (
    "groupId" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "joinedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PeerGroupMember_pkey" PRIMARY KEY ("groupId","studentId")
);

-- CreateTable
CREATE TABLE "public"."Reflection" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "promptText" TEXT NOT NULL,
    "responseText" TEXT,
    "promptType" "public"."PromptType" NOT NULL,
    "isSharedWithCounselor" BOOLEAN NOT NULL DEFAULT false,
    "wordCount" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Reflection_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ReflectionSession" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "monthKey" TEXT,
    "pulseScore" INTEGER,
    "pulseNote" TEXT,
    "completedAt" TIMESTAMP(3),
    "durationSeconds" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionNumber" INTEGER,
    "templateId" TEXT,

    CONSTRAINT "ReflectionSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ReflectionTemplate" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "orderNum" INTEGER NOT NULL,
    "yearKey" TEXT NOT NULL,
    "prompts" JSONB NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ReflectionTemplate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."School" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "district" TEXT,
    "state" TEXT,
    "tier" TEXT NOT NULL DEFAULT 'free',
    "licenseExpires" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "School_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."SignalProfile" (
    "id" TEXT NOT NULL,
    "studentId" TEXT NOT NULL,
    "interestClusters" JSONB NOT NULL DEFAULT '[]',
    "characterSignals" JSONB NOT NULL DEFAULT '[]',
    "trajectoryShifts" JSONB NOT NULL DEFAULT '[]',
    "gapDetection" JSONB NOT NULL DEFAULT '{}',
    "breadthScore" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "compressedSummary" TEXT,
    "lastSynthesizedAt" TIMESTAMP(3),
    "synthesisVersion" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SignalProfile_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Student" (
    "id" TEXT NOT NULL,
    "clerkId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "gradeLevel" INTEGER,
    "schoolId" TEXT,
    "onboardingCompleted" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Student_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."StudentPrivacySettings" (
    "studentId" TEXT NOT NULL,
    "shareInterestClusters" BOOLEAN NOT NULL DEFAULT true,
    "shareBreadthScore" BOOLEAN NOT NULL DEFAULT true,
    "shareTrajectoryShifts" BOOLEAN NOT NULL DEFAULT true,
    "shareCharacterSignals" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StudentPrivacySettings_pkey" PRIMARY KEY ("studentId")
);

-- CreateIndex
CREATE UNIQUE INDEX "Counselor_clerkId_key" ON "public"."Counselor"("clerkId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Counselor_email_key" ON "public"."Counselor"("email" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "MapEdge_sourceId_targetId_key" ON "public"."MapEdge"("sourceId" ASC, "targetId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "ReflectionTemplate_yearKey_orderNum_key" ON "public"."ReflectionTemplate"("yearKey" ASC, "orderNum" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Student_clerkId_key" ON "public"."Student"("clerkId" ASC);

-- CreateIndex
CREATE UNIQUE INDEX "Student_email_key" ON "public"."Student"("email" ASC);

-- AddForeignKey
ALTER TABLE "public"."Activity" ADD CONSTRAINT "Activity_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "public"."ReflectionSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Activity" ADD CONSTRAINT "Activity_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Counselor" ADD CONSTRAINT "Counselor_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "public"."School"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MapEdge" ADD CONSTRAINT "MapEdge_sourceId_fkey" FOREIGN KEY ("sourceId") REFERENCES "public"."MapNode"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MapEdge" ADD CONSTRAINT "MapEdge_targetId_fkey" FOREIGN KEY ("targetId") REFERENCES "public"."MapNode"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MapNode" ADD CONSTRAINT "MapNode_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "public"."MapNode"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Notification" ADD CONSTRAINT "Notification_relatedNodeId_fkey" FOREIGN KEY ("relatedNodeId") REFERENCES "public"."MapNode"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Notification" ADD CONSTRAINT "Notification_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."NotificationPreferences" ADD CONSTRAINT "NotificationPreferences_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PeerGroupMember" ADD CONSTRAINT "PeerGroupMember_groupId_fkey" FOREIGN KEY ("groupId") REFERENCES "public"."PeerGroup"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PeerGroupMember" ADD CONSTRAINT "PeerGroupMember_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Reflection" ADD CONSTRAINT "Reflection_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "public"."ReflectionSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Reflection" ADD CONSTRAINT "Reflection_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ReflectionSession" ADD CONSTRAINT "ReflectionSession_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ReflectionSession" ADD CONSTRAINT "ReflectionSession_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES "public"."ReflectionTemplate"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."SignalProfile" ADD CONSTRAINT "SignalProfile_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Student" ADD CONSTRAINT "Student_schoolId_fkey" FOREIGN KEY ("schoolId") REFERENCES "public"."School"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."StudentPrivacySettings" ADD CONSTRAINT "StudentPrivacySettings_studentId_fkey" FOREIGN KEY ("studentId") REFERENCES "public"."Student"("id") ON DELETE CASCADE ON UPDATE CASCADE;

