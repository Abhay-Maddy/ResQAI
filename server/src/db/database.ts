import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import { hash, Algorithm } from '@node-rs/argon2';

const DB_DIR = path.resolve(__dirname, '../../data');
if (!fs.existsSync(DB_DIR)) {
  fs.mkdirSync(DB_DIR, { recursive: true });
}

const DB_PATH = process.env.NODE_ENV === 'test' 
  ? ':memory:' 
  : path.join(DB_DIR, 'resqai.db');

export const db = new Database(DB_PATH);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

export async function initDatabase() {
  const schemaPath = path.resolve(__dirname, 'schema.sql');
  const schemaSql = fs.readFileSync(schemaPath, 'utf-8');
  db.exec(schemaSql);

  // Check if seed users exist
  const countStmt = db.prepare('SELECT count(*) as count FROM users');
  const userCount = (countStmt.get() as { count: number }).count;

  if (userCount === 0) {
    await seedInitialData();
  }
}

export async function seedInitialData() {
  // Precompute Argon2id hashes
  const defaultPasswordHash = await hash('Password123!', { algorithm: Algorithm.Argon2id });
  const adminPasswordHash = await hash('AdminPassword123!', { algorithm: Algorithm.Argon2id });

  const insertUser = db.prepare(`
    INSERT INTO users (id, name, email, phone, password_hash, role, jurisdiction_region_id, is_verified, two_factor_enabled, two_factor_secret)
    VALUES (@id, @name, @email, @phone, @password_hash, @role, @jurisdiction_region_id, @is_verified, @two_factor_enabled, @two_factor_secret)
  `);

  const seedUsers = [
    {
      id: 'USR-CITIZEN-01',
      name: 'Sunita Devi',
      email: 'sunita.citizen@resqai.org',
      phone: '+919876543210',
      password_hash: defaultPasswordHash,
      role: 'CITIZEN',
      jurisdiction_region_id: null,
      is_verified: 1,
      two_factor_enabled: 0,
      two_factor_secret: null
    },
    {
      id: 'USR-ADMIN-01',
      name: 'Rajesh Kumar (DDO)',
      email: 'admin@resqai.org',
      phone: '+919876543211',
      password_hash: adminPasswordHash,
      role: 'ADMIN',
      jurisdiction_region_id: null,
      is_verified: 1,
      two_factor_enabled: 1,
      two_factor_secret: 'RESQAI_ADMIN_2FA_SECRET'
    },
    {
      id: 'USR-GOVT-01',
      name: 'Inspector Meera Singh',
      email: 'meera.govt@resqai.org',
      phone: '+919876543212',
      password_hash: defaultPasswordHash,
      role: 'GOVT_OFFICER',
      jurisdiction_region_id: 'area-a',
      is_verified: 1,
      two_factor_enabled: 1,
      two_factor_secret: 'RESQAI_GOVT_2FA_SECRET'
    },
    {
      id: 'USR-RESPONDER-01',
      name: 'Team Lead Arjun',
      email: 'arjun.rescue@resqai.org',
      phone: '+919876543213',
      password_hash: defaultPasswordHash,
      role: 'RESPONDER',
      jurisdiction_region_id: 'area-a',
      is_verified: 1,
      two_factor_enabled: 0,
      two_factor_secret: null
    },
    {
      id: 'USR-NGO-01',
      name: 'Anita Sharma',
      email: 'anita.ngo@resqai.org',
      phone: '+919876543214',
      password_hash: defaultPasswordHash,
      role: 'NGO',
      jurisdiction_region_id: 'area-b',
      is_verified: 1,
      two_factor_enabled: 1,
      two_factor_secret: 'RESQAI_NGO_2FA_SECRET'
    },
    {
      id: 'USR-DONOR-01',
      name: 'Vikram Merchant',
      email: 'vikram.donor@resqai.org',
      phone: '+919876543215',
      password_hash: defaultPasswordHash,
      role: 'DONOR',
      jurisdiction_region_id: null,
      is_verified: 1,
      two_factor_enabled: 0,
      two_factor_secret: null
    },
    {
      id: 'USR-AUDITOR-01',
      name: 'Suresh Verma (CAG Auditor)',
      email: 'auditor@resqai.org',
      phone: '+919876543216',
      password_hash: defaultPasswordHash,
      role: 'AUDITOR',
      jurisdiction_region_id: null,
      is_verified: 1,
      two_factor_enabled: 0,
      two_factor_secret: null
    }
  ];

  for (const u of seedUsers) {
    insertUser.run(u);
  }

  // Seed Affected Areas (PRD E6 Worked Example: Area A, B, C)
  const insertArea = db.prepare(`
    INSERT INTO affected_areas (id, name, district, state, latitude, longitude)
    VALUES (@id, @name, @district, @state, @latitude, @longitude)
  `);

  const areas = [
    { id: 'area-a', name: 'Sector A (North River Basin)', district: 'Patna', state: 'Bihar', latitude: 25.612, longitude: 85.144 },
    { id: 'area-b', name: 'Sector B (Lowland Colony)', district: 'Patna', state: 'Bihar', latitude: 25.594, longitude: 85.122 },
    { id: 'area-c', name: 'Sector C (Elevated Ridge)', district: 'Patna', state: 'Bihar', latitude: 25.628, longitude: 85.168 }
  ];

  for (const a of areas) {
    insertArea.run(a);
  }

  // Seed Area Needs (PRD E6 Worked Example)
  const insertNeed = db.prepare(`
    INSERT INTO area_needs (id, area_id, resource_type, required_units, available_units, reserved_units, dispatched_units, delivered_units, pending_units, last_verified)
    VALUES (@id, @area_id, @resource_type, @required_units, @available_units, @reserved_units, @dispatched_units, @delivered_units, @pending_units, @last_verified)
  `);

  const needsList = [
    // Area A (Food 100%, Water 80%, Medicine 20%)
    { id: 'N-A-1', area_id: 'area-a', resource_type: 'FOOD', required_units: 500, available_units: 500, reserved_units: 50, dispatched_units: 350, delivered_units: 100, pending_units: 0, last_verified: '10 mins ago' },
    { id: 'N-A-2', area_id: 'area-a', resource_type: 'WATER', required_units: 1000, available_units: 800, reserved_units: 100, dispatched_units: 500, delivered_units: 200, pending_units: 200, last_verified: '15 mins ago' },
    { id: 'N-A-3', area_id: 'area-a', resource_type: 'MEDICINE', required_units: 300, available_units: 60, reserved_units: 10, dispatched_units: 30, delivered_units: 20, pending_units: 240, last_verified: '5 mins ago' },
    
    // Area B (Food 40%, Water 0%, Medicine 60%)
    { id: 'N-B-1', area_id: 'area-b', resource_type: 'FOOD', required_units: 400, available_units: 160, reserved_units: 20, dispatched_units: 100, delivered_units: 40, pending_units: 240, last_verified: '25 mins ago' },
    { id: 'N-B-2', area_id: 'area-b', resource_type: 'WATER', required_units: 800, available_units: 0, reserved_units: 0, dispatched_units: 0, delivered_units: 0, pending_units: 800, last_verified: '3 mins ago' },
    { id: 'N-B-3', area_id: 'area-b', resource_type: 'MEDICINE', required_units: 200, available_units: 120, reserved_units: 15, dispatched_units: 80, delivered_units: 25, pending_units: 80, last_verified: '18 mins ago' },

    // Area C (Food 95%, Water 90%, Medicine 90%)
    { id: 'N-C-1', area_id: 'area-c', resource_type: 'FOOD', required_units: 200, available_units: 190, reserved_units: 20, dispatched_units: 140, delivered_units: 30, pending_units: 10, last_verified: '1 hour ago' },
    { id: 'N-C-2', area_id: 'area-c', resource_type: 'WATER', required_units: 500, available_units: 450, reserved_units: 50, dispatched_units: 350, delivered_units: 50, pending_units: 50, last_verified: '45 mins ago' },
    { id: 'N-C-3', area_id: 'area-c', resource_type: 'MEDICINE', required_units: 100, available_units: 90, reserved_units: 10, dispatched_units: 70, delivered_units: 10, pending_units: 10, last_verified: '35 mins ago' }
  ];

  for (const n of needsList) {
    insertNeed.run(n);
  }

  // Seed Synthetic Drill Session (Part L Item 7)
  db.prepare(`
    INSERT INTO drill_sessions (id, drill_name, scenario_type, status, is_watermarked_synthetic, total_synthetic_incidents)
    VALUES ('DRILL-2026-DEMO', 'Operation Jal-Suraksha 2026 (Simulated)', 'URBAN_FLASH_FLOOD', 'ACTIVE', 1, 12)
  `).run();

  // Log initial system audit log entry (FR-53)
  db.prepare(`
    INSERT INTO audit_logs (id, action_type, actor_id, actor_role, entity_id, details)
    VALUES ('AUD-INIT-001', 'SYSTEM_INIT', 'SYSTEM', 'ADMIN', 'DB_INIT', 'ResQAI Database initialized with schema and Phase 0/1 seed records')
  `).run();
}
