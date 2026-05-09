# Goinus — Flask Backend

> Single-file Python REST API for the Goinus internship matching platform.

---

## Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Create the database
mysql -u root -p < schema.sql

# 3. Configure environment
cp .env .env          # edit DB_PASSWORD and SECRET_KEY

# 4. Run
python app.py
# → http://0.0.0.0:3000
```

---

## Folder Structure

```
goinus_backend/
├── app.py            ← entire backend (11 sections, ~700 lines)
├── .env              ← environment config (never commit this!)
├── requirements.txt
├── schema.sql        ← one-time DB setup
├── uploads/          ← created automatically for photos & CVs
└── README.md
```

---

## Architecture

```
Flask Routes
    │
    ▼
Service Layer          (AuthService, InternshipService, ApplicationService)
    │
    ▼
Repository Layer       (UserRepository, InternshipRepository, ApplicationRepository)
    │
    ▼
Database (Singleton)   mysql-connector connection pool → MySQL
```

### OOP Inheritance

```
BaseModel (ABC)
 ├── User
 │    ├── Intern    gpa · skills · major · cv_path · photo_url
 │    └── Company   company_name · industry · location · about
 ├── Internship
 └── Application
```

### Design Patterns

| Pattern | Class(es) |
|---------|-----------|
| **Singleton** | `Config`, `Database`, `EventBus` |
| **Repository** | `UserRepository`, `InternshipRepository`, `ApplicationRepository` |
| **Factory** | `UserFactory.create()` · `UserFactory.from_row()` |
| **Strategy** | `MatchingStrategy` → `SkillsAndGpaStrategy`, `KeywordMatchingStrategy` |
| **Observer** | `EventBus` + `EventObserver` → `LogObserver` |

---

## API Reference

### Public

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` or `/health` | Health check |
| POST | `/register` | Register intern or company |
| POST | `/login` | Login → JWT |
| GET | `/internships` | List all active internships |
| GET | `/internships?q=&location=&field=` | Search internships |
| GET | `/internships/<id>` | Get one internship (increments views) |
| GET | `/matches` | Personalised matches (JWT optional) |

### Authenticated (any role)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/me` | Current user profile |
| PUT | `/profile` | Update profile |
| POST | `/apply` | Apply for internship |
| GET | `/applications` | List my applications (intern) |
| POST | `/upload-photo` | Upload profile photo |
| POST | `/upload-cv` | Upload CV (PDF/DOC) |
| GET | `/uploads/<filename>` | Serve uploaded file |

### Company only

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/internships` | Post new internship |
| PUT | `/internships/<id>` | Edit internship |
| DELETE | `/internships/<id>` | Delete internship |
| POST | `/internships/<id>/close` | Close applications |
| POST | `/internships/<id>/open` | Re-open applications |
| GET | `/internships/mine` | My internship listings |
| GET | `/applications?internshipId=` | View applicants |
| PUT | `/applications/<id>` | Accept / reject |
| GET | `/analytics/internship/<id>` | Stats for one internship |
| GET | `/analytics/dashboard` | Aggregate company stats |
| GET | `/candidates?skills=&major=&min_gpa=` | Search interns |

---

## Matching Algorithm

`SkillsAndGpaStrategy` (default for interns with skills/GPA):

```
score = (skills_overlap / total_requirements) × 60
      + (intern_gpa / 4.0) × 40
```

`KeywordMatchingStrategy` (fallback for guests / minimal profiles):

```
score = min(keyword_overlap × 15, 95)
```

---

## Request / Response Examples

### Register (intern)
```json
POST /register
{
  "name": "Nicole Chou",
  "email": "nicole@student.cm",
  "password": "secret123",
  "type": "intern",
  "gpa": 3.68,
  "major": "Computer Science",
  "skills": ["Python", "SQL", "React"]
}
→ 201 { "token": "eyJ...", "user": { ... } }
```

### Register (company)
```json
POST /register
{
  "name": "HR Manager",
  "email": "hr@techcorp.cm",
  "password": "secret123",
  "type": "company",
  "company": "TechCorp Cameroon",
  "industry": "Technology",
  "location": "Yaoundé"
}
→ 201 { "token": "eyJ...", "user": { ... } }
```

### Post internship
```json
POST /internships
Authorization: Bearer <company_token>
{
  "title": "Software Intern",
  "description": "Work on our mobile app.",
  "location": "Yaoundé",
  "field": "Technology",
  "requirements": ["Flutter", "Python"],
  "deadline": "2025-09-01"
}
→ 201 { "id": "uuid", "message": "Internship posted successfully" }
```

### Apply
```json
POST /apply
Authorization: Bearer <intern_token>
{
  "internshipId": "uuid",
  "gpa": 3.68,
  "aboutMe": "Passionate CS student looking for hands-on experience."
}
→ 201 { "id": "uuid", "message": "Application submitted successfully" }
```

---

## Security

- Passwords hashed with **bcrypt** (cost 12)
- Auth via **JWT** HS256, configurable expiry (default 72 h)
- File uploads validated by extension allowlist
- All SQL via parameterised queries — no injection risk
- File size capped at `MAX_FILE_MB` (default 10 MB)
- CORS headers open for Flutter → Flask local dev

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SECRET_KEY` | `goinus_change_me_2025` | JWT signing secret |
| `JWT_EXPIRY_HOURS` | `72` | Token lifetime |
| `PORT` | `3000` | HTTP port |
| `DB_HOST` | `localhost` | MySQL host |
| `DB_PORT` | `3306` | MySQL port |
| `DB_USER` | `root` | MySQL user |
| `DB_PASSWORD` | _(empty)_ | MySQL password |
| `DB_NAME` | `goinus_db` | Database name |
| `DB_POOL_SIZE` | `5` | Connection pool size |
| `UPLOAD_FOLDER` | `uploads` | Upload directory |
| `MAX_FILE_MB` | `10` | Max upload size |
| `FLASK_DEBUG` | `1` | Debug mode (set 0 in prod) |
