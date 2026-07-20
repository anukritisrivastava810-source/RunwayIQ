import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  /**
   * Path to your Prisma schema file.
   * This replaces the deprecated `package.json#prisma.schema` field.
   */
  schema: 'prisma/schema.prisma',
});
