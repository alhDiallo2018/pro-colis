-- Add audio support to chat messages, and allow empty body (audio-only messages).
ALTER TABLE "messages" ALTER COLUMN "body" SET DEFAULT '';
ALTER TABLE "messages" ADD COLUMN "audio_url" TEXT;
