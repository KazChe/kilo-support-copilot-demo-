import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.join(__dirname, '..', '.env') });
dotenv.config({ path: path.join(__dirname, '..', '.env.local'), override: true });

export const config = {
  apiKey: process.env.API_KEY ?? '',
  port: Number(process.env.PORT ?? 3000),
};
