"""
Goinus - Job & Internship Matching Platform
Flask Backend (Single File)
Design Patterns: Repository, Factory, Singleton, Observer, Strategy
OOP: Inheritance hierarchy (User -> Intern/Company), Application, Internship
Database: MySQL via mysql-connector-python
"""

from __future__ import annotations
import os
import uuid
import bcrypt
import jwt
import datetime
import re
from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any
from functools import wraps

# Load .env file automatically if python-dotenv is installed
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass  # python-dotenv not installed — fall back to real env vars

import mysql.connector
from mysql.connector import pooling
from flask import Flask, request, jsonify, g
from werkzeug.utils import secure_filename

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURATION (Singleton Pattern)
# ─────────────────────────────────────────────────────────────────────────────

class Config:
    """Singleton configuration object."""
    _instance: Optional[Config] = None

    def __new__(cls) -> Config:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._init()
        return cls._instance

    def _init(self):
        self.SECRET_KEY       = os.getenv("SECRET_KEY", "goinus_super_secret_2025")
        self.JWT_EXPIRY_HOURS = int(os.getenv("JWT_EXPIRY_HOURS", "72"))
        self.UPLOAD_FOLDER    = os.getenv("UPLOAD_FOLDER", "uploads")
        self.MAX_FILE_MB      = int(os.getenv("MAX_FILE_MB", "10"))
        self.DB_HOST          = os.getenv("DB_HOST", "localhost")
        self.DB_PORT          = int(os.getenv("DB_PORT", "3306"))
        self.DB_USER          = os.getenv("DB_USER", "root")
        self.DB_PASSWORD      = os.getenv("DB_PASSWORD", "")
        self.DB_NAME          = os.getenv("DB_NAME", "goinus_db")
        self.POOL_SIZE        = int(os.getenv("DB_POOL_SIZE", "5"))
        os.makedirs(self.UPLOAD_FOLDER, exist_ok=True)


# ─────────────────────────────────────────────────────────────────────────────
# DATABASE (Singleton Connection Pool)
# ─────────────────────────────────────────────────────────────────────────────

class Database:
    """Singleton MySQL connection pool."""
    _instance: Optional[Database] = None
    _pool = None

    def __new__(cls) -> Database:
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cfg = Config()
            cls._pool = pooling.MySQLConnectionPool(
                pool_name="goinus_pool",
                pool_size=cfg.POOL_SIZE,
                host=cfg.DB_HOST,
                port=cfg.DB_PORT,
                user=cfg.DB_USER,
                password=cfg.DB_PASSWORD,
                database=cfg.DB_NAME,
                autocommit=False,
                charset="utf8mb4",
            )
        return cls._instance

    def get_connection(self):
        return self._pool.get_connection()

    def execute(self, sql: str, params: tuple = (), fetch: bool = False):
        conn = self.get_connection()
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute(sql, params)
            result = cursor.fetchall() if fetch else None
            conn.commit()
            return result
        except Exception:
            conn.rollback()
            raise
        finally:
            cursor.close()
            conn.close()

    def execute_one(self, sql: str, params: tuple = ()) -> Optional[Dict]:
        rows = self.execute(sql, params, fetch=True)
        return rows[0] if rows else None

    def execute_many(self, sql: str, params: tuple = ()) -> List[Dict]:
        return self.execute(sql, params, fetch=True) or []


# ─────────────────────────────────────────────────────────────────────────────
# DOMAIN MODELS (OOP Inheritance)
# ─────────────────────────────────────────────────────────────────────────────

class BaseModel(ABC):
    """Abstract base for all domain objects."""

    @abstractmethod
    def to_dict(self) -> Dict[str, Any]:
        pass

    @classmethod
    @abstractmethod
    def from_row(cls, row: Dict[str, Any]) -> "BaseModel":
        pass


class User(BaseModel):
    """Base user entity."""

    def __init__(self, id: str, name: str, email: str,
                 password_hash: str, user_type: str,
                 is_verified: bool = False, created_at=None):
        self.id            = id
        self.name          = name
        self.email         = email
        self.password_hash = password_hash
        self.user_type     = user_type  # 'intern' | 'company'
        self.is_verified   = is_verified
        self.created_at    = created_at or datetime.datetime.utcnow()

    def check_password(self, raw: str) -> bool:
        return bcrypt.checkpw(raw.encode(), self.password_hash.encode())

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id":          self.id,
            "name":        self.name,
            "email":       self.email,
            "type":        self.user_type,
            "isVerified":  self.is_verified,
            "createdAt":   str(self.created_at),
        }

    @classmethod
    def from_row(cls, row: Dict) -> "User":
        return cls(
            id=row["id"], name=row["name"], email=row["email"],
            password_hash=row["password_hash"], user_type=row["user_type"],
            is_verified=bool(row.get("is_verified", False)),
            created_at=row.get("created_at"),
        )


class Intern(User):
    """Student / intern profile."""

    def __init__(self, *args,
                 gpa: Optional[float] = None,
                 skills: Optional[List[str]] = None,
                 major: Optional[str] = None,
                 about_me: Optional[str] = None,
                 education_history: Optional[str] = None,
                 cv_path: Optional[str] = None,
                 photo_url: Optional[str] = None,
                 **kwargs):
        super().__init__(*args, user_type="intern", **kwargs)
        self.gpa               = gpa
        self.skills            = skills or []
        self.major             = major
        self.about_me          = about_me
        self.education_history = education_history
        self.cv_path           = cv_path
        self.photo_url         = photo_url

    def to_dict(self) -> Dict[str, Any]:
        d = super().to_dict()
        d.update({
            "gpa":              self.gpa,
            "skills":           self.skills,
            "major":            self.major,
            "aboutMe":          self.about_me,
            "educationHistory": self.education_history,
            "cvPath":           self.cv_path,
            "photoUrl":         self.photo_url,
        })
        return d

    @classmethod
    def from_row(cls, row: Dict) -> "Intern":
        skills_raw = row.get("skills") or ""
        skills = [s.strip() for s in skills_raw.split(",") if s.strip()] if skills_raw else []
        return cls(
            id=row["id"], name=row["name"], email=row["email"],
            password_hash=row["password_hash"],
            is_verified=bool(row.get("is_verified", False)),
            created_at=row.get("created_at"),
            gpa=row.get("gpa"),
            skills=skills,
            major=row.get("major"),
            about_me=row.get("about_me"),
            education_history=row.get("education_history"),
            cv_path=row.get("cv_path"),
            photo_url=row.get("photo_url"),
        )


class Company(User):
    """Employer / company profile."""

    def __init__(self, *args,
                 company_name: Optional[str] = None,
                 industry: Optional[str] = None,
                 location: Optional[str] = None,
                 about: Optional[str] = None,
                 logo_url: Optional[str] = None,
                 **kwargs):
        super().__init__(*args, user_type="company", **kwargs)
        self.company_name = company_name
        self.industry     = industry
        self.location     = location
        self.about        = about
        self.logo_url     = logo_url

    def to_dict(self) -> Dict[str, Any]:
        d = super().to_dict()
        d.update({
            "companyName": self.company_name,
            "industry":    self.industry,
            "location":    self.location,
            "about":       self.about,
            "logoUrl":     self.logo_url,
        })
        return d

    @classmethod
    def from_row(cls, row: Dict) -> "Company":
        return cls(
            id=row["id"], name=row["name"], email=row["email"],
            password_hash=row["password_hash"],
            is_verified=bool(row.get("is_verified", False)),
            created_at=row.get("created_at"),
            company_name=row.get("company_name"),
            industry=row.get("industry"),
            location=row.get("location"),
            about=row.get("about"),
            logo_url=row.get("logo_url"),
        )


class Internship(BaseModel):
    """Internship listing posted by a company."""

    def __init__(self, id: str, title: str, description: str,
                 company_id: str, company_name: str,
                 location: str, field: str,
                 requirements: List[str], deadline: datetime.date,
                 is_active: bool = True, created_at=None,
                 views: int = 0, applications_count: int = 0):
        self.id                  = id
        self.title               = title
        self.description         = description
        self.company_id          = company_id
        self.company_name        = company_name
        self.location            = location
        self.field               = field
        self.requirements        = requirements
        self.deadline            = deadline
        self.is_active           = is_active
        self.created_at          = created_at or datetime.datetime.utcnow()
        self.views               = views
        self.applications_count  = applications_count

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id":               self.id,
            "title":            self.title,
            "description":      self.description,
            "companyId":        self.company_id,
            "companyName":      self.company_name,
            "location":         self.location,
            "field":            self.field,
            "requirements":     self.requirements,
            "deadline":         str(self.deadline),
            "isActive":         self.is_active,
            "createdAt":        str(self.created_at),
            "views":            self.views,
            "applicationsCount": self.applications_count,
        }

    @classmethod
    def from_row(cls, row: Dict) -> "Internship":
        reqs_raw = row.get("requirements") or ""
        reqs = [r.strip() for r in reqs_raw.split(",") if r.strip()]
        return cls(
            id=row["id"], title=row["title"], description=row["description"],
            company_id=row["company_id"], company_name=row.get("company_name", ""),
            location=row["location"], field=row["field"],
            requirements=reqs, deadline=row["deadline"],
            is_active=bool(row.get("is_active", True)),
            created_at=row.get("created_at"),
            views=row.get("views", 0),
            applications_count=row.get("applications_count", 0),
        )


class Application(BaseModel):
    """Internship application submitted by an intern."""

    def __init__(self, id: str, intern_id: str, internship_id: str,
                 status: str = "pending",
                 gpa: Optional[float] = None,
                 about_me: Optional[str] = None,
                 documents: Optional[List[str]] = None,
                 created_at=None):
        self.id           = id
        self.intern_id    = intern_id
        self.internship_id = internship_id
        self.status       = status  # pending | accepted | rejected
        self.gpa          = gpa
        self.about_me     = about_me
        self.documents    = documents or []
        self.created_at   = created_at or datetime.datetime.utcnow()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id":           self.id,
            "internId":     self.intern_id,
            "internshipId": self.internship_id,
            "status":       self.status,
            "gpa":          self.gpa,
            "aboutMe":      self.about_me,
            "documents":    self.documents,
            "createdAt":    str(self.created_at),
        }

    @classmethod
    def from_row(cls, row: Dict) -> "Application":
        docs_raw = row.get("documents") or ""
        docs = [d.strip() for d in docs_raw.split(",") if d.strip()]
        return cls(
            id=row["id"], intern_id=row["intern_id"],
            internship_id=row["internship_id"], status=row["status"],
            gpa=row.get("gpa"), about_me=row.get("about_me"),
            documents=docs, created_at=row.get("created_at"),
        )


# ─────────────────────────────────────────────────────────────────────────────
# FACTORY PATTERN — UserFactory
# ─────────────────────────────────────────────────────────────────────────────

class UserFactory:
    """Creates the correct User subclass based on type string."""

    @staticmethod
    def create(user_type: str, **kwargs) -> User:
        t = user_type.lower()
        if t in ("intern", "jobseeker", "student"):
            return Intern(**kwargs)
        elif t in ("company", "employer"):
            return Company(**kwargs)
        raise ValueError(f"Unknown user type: {user_type}")

    @staticmethod
    def from_row(row: Dict) -> User:
        if row["user_type"] in ("intern", "jobseeker", "student"):
            return Intern.from_row(row)
        return Company.from_row(row)


# ─────────────────────────────────────────────────────────────────────────────
# REPOSITORY PATTERN
# ─────────────────────────────────────────────────────────────────────────────

class BaseRepository(ABC):
    def __init__(self):
        self.db = Database()


class UserRepository(BaseRepository):

    def find_by_email(self, email: str) -> Optional[User]:
        row = self.db.execute_one(
            "SELECT u.*, ip.gpa, ip.skills, ip.major, ip.about_me, "
            "ip.education_history, ip.cv_path, ip.photo_url, "
            "cp.company_name, cp.industry, cp.location AS cp_location, "
            "cp.about, cp.logo_url "
            "FROM users u "
            "LEFT JOIN intern_profiles ip ON u.id = ip.user_id "
            "LEFT JOIN company_profiles cp ON u.id = cp.user_id "
            "WHERE u.email = %s",
            (email,)
        )
        return UserFactory.from_row(row) if row else None

    def find_by_id(self, user_id: str) -> Optional[User]:
        row = self.db.execute_one(
            "SELECT u.*, ip.gpa, ip.skills, ip.major, ip.about_me, "
            "ip.education_history, ip.cv_path, ip.photo_url, "
            "cp.company_name, cp.industry, cp.location AS cp_location, "
            "cp.about, cp.logo_url "
            "FROM users u "
            "LEFT JOIN intern_profiles ip ON u.id = ip.user_id "
            "LEFT JOIN company_profiles cp ON u.id = cp.user_id "
            "WHERE u.id = %s",
            (user_id,)
        )
        return UserFactory.from_row(row) if row else None

    def save(self, user: User) -> None:
        self.db.execute(
            "INSERT INTO users (id, name, email, password_hash, user_type, is_verified) "
            "VALUES (%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE name=%s, email=%s",
            (user.id, user.name, user.email, user.password_hash,
             user.user_type, user.is_verified,
             user.name, user.email)
        )
        if isinstance(user, Intern):
            skills_str = ",".join(user.skills or [])
            self.db.execute(
                "INSERT INTO intern_profiles "
                "(user_id, gpa, skills, major, about_me, education_history, cv_path, photo_url) "
                "VALUES (%s,%s,%s,%s,%s,%s,%s,%s) "
                "ON DUPLICATE KEY UPDATE "
                "gpa=%s, skills=%s, major=%s, about_me=%s, "
                "education_history=%s, cv_path=%s, photo_url=%s",
                (user.id, user.gpa, skills_str, user.major, user.about_me,
                 user.education_history, user.cv_path, user.photo_url,
                 user.gpa, skills_str, user.major, user.about_me,
                 user.education_history, user.cv_path, user.photo_url)
            )
        elif isinstance(user, Company):
            self.db.execute(
                "INSERT INTO company_profiles "
                "(user_id, company_name, industry, location, about, logo_url) "
                "VALUES (%s,%s,%s,%s,%s,%s) "
                "ON DUPLICATE KEY UPDATE "
                "company_name=%s, industry=%s, location=%s, about=%s, logo_url=%s",
                (user.id, user.company_name, user.industry, user.location,
                 user.about, user.logo_url,
                 user.company_name, user.industry, user.location,
                 user.about, user.logo_url)
            )

    def update_photo(self, user_id: str, photo_url: str) -> None:
        self.db.execute(
            "UPDATE intern_profiles SET photo_url=%s WHERE user_id=%s",
            (photo_url, user_id)
        )

    def update_cv(self, user_id: str, cv_path: str) -> None:
        self.db.execute(
            "UPDATE intern_profiles SET cv_path=%s WHERE user_id=%s",
            (cv_path, user_id)
        )


class InternshipRepository(BaseRepository):

    def find_all(self, only_active: bool = True) -> List[Internship]:
        sql = (
            "SELECT i.*, c.company_name, "
            "(SELECT COUNT(*) FROM applications a WHERE a.internship_id=i.id) AS applications_count "
            "FROM internships i "
            "JOIN company_profiles c ON i.company_id = c.user_id "
        )
        if only_active:
            sql += "WHERE i.is_active=1 AND i.deadline >= CURDATE() "
        sql += "ORDER BY i.created_at DESC"
        rows = self.db.execute_many(sql)
        return [Internship.from_row(r) for r in rows]

    def find_by_id(self, internship_id: str) -> Optional[Internship]:
        row = self.db.execute_one(
            "SELECT i.*, c.company_name, "
            "(SELECT COUNT(*) FROM applications a WHERE a.internship_id=i.id) AS applications_count "
            "FROM internships i "
            "JOIN company_profiles c ON i.company_id = c.user_id "
            "WHERE i.id=%s",
            (internship_id,)
        )
        return Internship.from_row(row) if row else None

    def find_by_company(self, company_id: str) -> List[Internship]:
        rows = self.db.execute_many(
            "SELECT i.*, c.company_name, "
            "(SELECT COUNT(*) FROM applications a WHERE a.internship_id=i.id) AS applications_count "
            "FROM internships i "
            "JOIN company_profiles c ON i.company_id = c.user_id "
            "WHERE i.company_id=%s ORDER BY i.created_at DESC",
            (company_id,)
        )
        return [Internship.from_row(r) for r in rows]

    def save(self, internship: Internship) -> None:
        reqs_str = ",".join(internship.requirements)
        self.db.execute(
            "INSERT INTO internships "
            "(id, title, description, company_id, location, field, requirements, deadline, is_active) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE "
            "title=%s, description=%s, location=%s, field=%s, "
            "requirements=%s, deadline=%s, is_active=%s",
            (internship.id, internship.title, internship.description,
             internship.company_id, internship.location, internship.field,
             reqs_str, internship.deadline, internship.is_active,
             internship.title, internship.description, internship.location,
             internship.field, reqs_str, internship.deadline, internship.is_active)
        )

    def delete(self, internship_id: str) -> None:
        self.db.execute(
            "DELETE FROM internships WHERE id=%s", (internship_id,)
        )

    def increment_views(self, internship_id: str) -> None:
        self.db.execute(
            "UPDATE internships SET views = views + 1 WHERE id=%s",
            (internship_id,)
        )

    def search(self, keyword: str = "", location: str = "", field: str = "") -> List[Internship]:
        conditions = ["i.is_active=1", "i.deadline >= CURDATE()"]
        params = []
        if keyword:
            conditions.append(
                "(i.title LIKE %s OR i.description LIKE %s OR i.requirements LIKE %s)"
            )
            like = f"%{keyword}%"
            params += [like, like, like]
        if location:
            conditions.append("i.location LIKE %s")
            params.append(f"%{location}%")
        if field:
            conditions.append("i.field LIKE %s")
            params.append(f"%{field}%")

        where = " AND ".join(conditions)
        rows = self.db.execute_many(
            f"SELECT i.*, c.company_name, "
            f"(SELECT COUNT(*) FROM applications a WHERE a.internship_id=i.id) AS applications_count "
            f"FROM internships i "
            f"JOIN company_profiles c ON i.company_id = c.user_id "
            f"WHERE {where} ORDER BY i.created_at DESC",
            tuple(params)
        )
        return [Internship.from_row(r) for r in rows]


class ApplicationRepository(BaseRepository):

    def find_by_intern(self, intern_id: str) -> List[Application]:
        rows = self.db.execute_many(
            "SELECT * FROM applications WHERE intern_id=%s ORDER BY created_at DESC",
            (intern_id,)
        )
        return [Application.from_row(r) for r in rows]

    def find_by_internship(self, internship_id: str) -> List[Application]:
        rows = self.db.execute_many(
            "SELECT * FROM applications WHERE internship_id=%s ORDER BY created_at DESC",
            (internship_id,)
        )
        return [Application.from_row(r) for r in rows]

    def find_by_id(self, app_id: str) -> Optional[Application]:
        row = self.db.execute_one(
            "SELECT * FROM applications WHERE id=%s", (app_id,)
        )
        return Application.from_row(row) if row else None

    def exists(self, intern_id: str, internship_id: str) -> bool:
        row = self.db.execute_one(
            "SELECT id FROM applications WHERE intern_id=%s AND internship_id=%s",
            (intern_id, internship_id)
        )
        return row is not None

    def save(self, app: Application) -> None:
        docs_str = ",".join(app.documents or [])
        self.db.execute(
            "INSERT INTO applications "
            "(id, intern_id, internship_id, status, gpa, about_me, documents) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE status=%s",
            (app.id, app.intern_id, app.internship_id, app.status,
             app.gpa, app.about_me, docs_str, app.status)
        )

    def update_status(self, app_id: str, status: str) -> None:
        self.db.execute(
            "UPDATE applications SET status=%s WHERE id=%s", (status, app_id)
        )


# ─────────────────────────────────────────────────────────────────────────────
# STRATEGY PATTERN — Matching
# ─────────────────────────────────────────────────────────────────────────────

class MatchingStrategy(ABC):
    @abstractmethod
    def match(self, intern: Intern, internships: List[Internship]) -> List[Dict]:
        pass


class SkillsAndGpaStrategy(MatchingStrategy):
    """Score = (skills overlap * 60) + (GPA score * 40)"""

    def match(self, intern: Intern, internships: List[Internship]) -> List[Dict]:
        results = []
        intern_skills = set(s.lower() for s in (intern.skills or []))
        intern_gpa    = intern.gpa or 0.0

        for job in internships:
            req_skills = set(r.lower() for r in job.requirements)
            skill_score = (len(intern_skills & req_skills) / max(len(req_skills), 1)) * 60
            gpa_score   = min((intern_gpa / 4.0) * 40, 40)
            total        = round(skill_score + gpa_score)
            results.append({"score": total, "internship": job})

        results.sort(key=lambda x: x["score"], reverse=True)
        return results


class KeywordMatchingStrategy(MatchingStrategy):
    """Simple keyword overlap fallback."""

    def match(self, intern: Intern, internships: List[Internship]) -> List[Dict]:
        results = []
        intern_keywords = set((intern.major or "").lower().split())
        intern_keywords |= set(s.lower() for s in (intern.skills or []))

        for job in internships:
            job_keywords = set(job.field.lower().split()) | set(
                w for r in job.requirements for w in r.lower().split()
            )
            overlap = len(intern_keywords & job_keywords)
            score   = min(overlap * 15, 95)
            results.append({"score": score, "internship": job})

        results.sort(key=lambda x: x["score"], reverse=True)
        return results


class MatchingContext:
    """Context for Strategy pattern."""

    def __init__(self, strategy: MatchingStrategy = None):
        self._strategy = strategy or SkillsAndGpaStrategy()

    def set_strategy(self, strategy: MatchingStrategy):
        self._strategy = strategy

    def get_matches(self, intern: Intern, internships: List[Internship]) -> List[Dict]:
        return self._strategy.match(intern, internships)


# ─────────────────────────────────────────────────────────────────────────────
# OBSERVER PATTERN — Events (extensible for notifications, emails, etc.)
# ─────────────────────────────────────────────────────────────────────────────

class EventObserver(ABC):
    @abstractmethod
    def on_event(self, event_type: str, data: Dict):
        pass


class LogObserver(EventObserver):
    def on_event(self, event_type: str, data: Dict):
        print(f"[EVENT] {event_type}: {data}")


class EventBus:
    _instance: Optional[EventBus] = None
    _observers: List[EventObserver] = []

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def subscribe(self, observer: EventObserver):
        self._observers.append(observer)

    def publish(self, event_type: str, data: Dict):
        for obs in self._observers:
            try:
                obs.on_event(event_type, data)
            except Exception:
                pass


# ─────────────────────────────────────────────────────────────────────────────
# SERVICE LAYER
# ─────────────────────────────────────────────────────────────────────────────

class AuthService:
    def __init__(self):
        self.user_repo = UserRepository()
        self.cfg       = Config()
        self.bus       = EventBus()

    def _hash(self, password: str) -> str:
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    def _token(self, user: User) -> str:
        payload = {
            "sub":  user.id,
            "type": user.user_type,
            "exp":  datetime.datetime.utcnow() + datetime.timedelta(
                        hours=self.cfg.JWT_EXPIRY_HOURS),
        }
        return jwt.encode(payload, self.cfg.SECRET_KEY, algorithm="HS256")

    def register(self, data: Dict) -> Dict:
        if not re.match(r"[^@]+@[^@]+\.[^@]+", data.get("email", "")):
            return {"error": "Invalid email address"}, 400

        if self.user_repo.find_by_email(data["email"]):
            return {"error": "Email already in use"}, 409

        user_id = str(uuid.uuid4())
        pwd_hash = self._hash(data["password"])
        user_type = data.get("type", "intern")

        if user_type in ("company", "employer"):
            user = Company(
                id=user_id, name=data["name"], email=data["email"],
                password_hash=pwd_hash, user_type="company",
                company_name=data.get("company"),
                industry=data.get("industry"),
                location=data.get("location"),
            )
        else:
            skills = data.get("skills", [])
            if isinstance(skills, str):
                skills = [s.strip() for s in skills.split(",") if s.strip()]
            user = Intern(
                id=user_id, name=data["name"], email=data["email"],
                password_hash=pwd_hash, user_type="intern",
                skills=skills, major=data.get("major"),
                gpa=data.get("gpa"),
            )

        self.user_repo.save(user)
        self.bus.publish("user_registered", {"id": user_id, "email": user.email})
        token = self._token(user)
        return {"token": token, "user": user.to_dict()}, 201

    def login(self, email: str, password: str) -> Dict:
        user = self.user_repo.find_by_email(email)
        if not user or not user.check_password(password):
            return {"error": "Invalid credentials"}, 401
        self.bus.publish("user_login", {"id": user.id})
        return {"token": self._token(user), "user": user.to_dict()}, 200


class InternshipService:
    def __init__(self):
        self.repo     = InternshipRepository()
        self.user_repo = UserRepository()
        self.bus      = EventBus()

    def create(self, company_id: str, data: Dict) -> Dict:
        reqs = data.get("requirements", [])
        if isinstance(reqs, str):
            reqs = [r.strip() for r in reqs.split(",") if r.strip()]

        internship = Internship(
            id=str(uuid.uuid4()),
            title=data["title"],
            description=data["description"],
            company_id=company_id,
            company_name="",  # will be resolved on read
            location=data["location"],
            field=data["field"],
            requirements=reqs,
            deadline=datetime.datetime.fromisoformat(data["deadline"]).date(),
        )
        self.repo.save(internship)
        self.bus.publish("internship_posted", {"id": internship.id})
        return {"id": internship.id, "message": "Internship posted successfully"}, 201

    def list_all(self) -> List[Dict]:
        return [i.to_dict() for i in self.repo.find_all()]

    def search(self, keyword: str, location: str, field: str) -> List[Dict]:
        return [i.to_dict() for i in self.repo.search(keyword, location, field)]

    def get_matches(self, intern_id: str) -> List[Dict]:
        user = self.user_repo.find_by_id(intern_id)
        if not isinstance(user, Intern):
            return []
        all_internships = self.repo.find_all()
        ctx = MatchingContext()
        matches = ctx.get_matches(user, all_internships)
        result = []
        for m in matches:
            d = m["internship"].to_dict()
            d["matchScore"] = m["score"]
            result.append(d)
        return result

    def delete(self, internship_id: str, company_id: str) -> Dict:
        internship = self.repo.find_by_id(internship_id)
        if not internship:
            return {"error": "Not found"}, 404
        if internship.company_id != company_id:
            return {"error": "Forbidden"}, 403
        self.repo.delete(internship_id)
        return {"message": "Deleted"}, 200


class ApplicationService:
    def __init__(self):
        self.app_repo  = ApplicationRepository()
        self.job_repo  = InternshipRepository()
        self.bus       = EventBus()

    def apply(self, intern_id: str, data: Dict) -> Dict:
        internship_id = data.get("internshipId")
        if not internship_id:
            return {"error": "internshipId required"}, 400
        if self.app_repo.exists(intern_id, internship_id):
            return {"error": "Already applied"}, 409

        app = Application(
            id=str(uuid.uuid4()),
            intern_id=intern_id,
            internship_id=internship_id,
            gpa=data.get("gpa"),
            about_me=data.get("aboutMe"),
            documents=data.get("documents", []),
        )
        self.app_repo.save(app)
        self.bus.publish("application_submitted", {"id": app.id})
        return {"message": "Application submitted", "id": app.id}, 201

    def get_for_intern(self, intern_id: str) -> List[Dict]:
        return [a.to_dict() for a in self.app_repo.find_by_intern(intern_id)]

    def get_for_internship(self, internship_id: str, company_id: str) -> Dict:
        internship = self.job_repo.find_by_id(internship_id)
        if not internship or internship.company_id != company_id:
            return {"error": "Forbidden"}, 403
        apps = self.app_repo.find_by_internship(internship_id)
        return [a.to_dict() for a in apps], 200

    def update_status(self, app_id: str, status: str, company_id: str) -> Dict:
        if status not in ("pending", "accepted", "rejected"):
            return {"error": "Invalid status"}, 400
        app = self.app_repo.find_by_id(app_id)
        if not app:
            return {"error": "Not found"}, 404
        internship = self.job_repo.find_by_id(app.internship_id)
        if not internship or internship.company_id != company_id:
            return {"error": "Forbidden"}, 403
        self.app_repo.update_status(app_id, status)
        self.bus.publish("application_status_changed",
                         {"id": app_id, "status": status})
        return {"message": "Status updated"}, 200


# ─────────────────────────────────────────────────────────────────────────────
# FLASK APP + MIDDLEWARE
# ─────────────────────────────────────────────────────────────────────────────

app = Flask(__name__)
cfg = Config()

# Wire up observer
bus = EventBus()
bus.subscribe(LogObserver())


# ── JWT middleware ────────────────────────────────────────────────────────────

def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Missing token"}), 401
        token = auth.split(" ", 1)[1]
        try:
            payload = jwt.decode(token, cfg.SECRET_KEY, algorithms=["HS256"])
            g.user_id   = payload["sub"]
            g.user_type = payload["type"]
        except jwt.ExpiredSignatureError:
            return jsonify({"error": "Token expired"}), 401
        except jwt.InvalidTokenError:
            return jsonify({"error": "Invalid token"}), 401
        return f(*args, **kwargs)
    return decorated


def company_required(f):
    @wraps(f)
    @jwt_required
    def decorated(*args, **kwargs):
        if g.user_type not in ("company", "employer"):
            return jsonify({"error": "Company access required"}), 403
        return f(*args, **kwargs)
    return decorated


def intern_required(f):
    @wraps(f)
    @jwt_required
    def decorated(*args, **kwargs):
        if g.user_type not in ("intern", "jobseeker", "student"):
            return jsonify({"error": "Intern access required"}), 403
        return f(*args, **kwargs)
    return decorated


# ── CORS ──────────────────────────────────────────────────────────────────────

@app.after_request
def add_cors(response):
    response.headers["Access-Control-Allow-Origin"]  = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
    return response

@app.route("/<path:path>", methods=["OPTIONS"])
def options_handler(path):
    return jsonify({}), 200


# ─────────────────────────────────────────────────────────────────────────────
# ROUTES
# ─────────────────────────────────────────────────────────────────────────────

auth_svc   = AuthService()
intern_svc = InternshipService()
app_svc    = ApplicationService()
user_repo  = UserRepository()


@app.route("/register", methods=["POST"])
def register():
    data = request.get_json(force=True) or {}
    result, code = auth_svc.register(data)
    return jsonify(result), code


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(force=True) or {}
    result, code = auth_svc.login(data.get("email", ""), data.get("password", ""))
    return jsonify(result), code


@app.route("/me", methods=["GET"])
@jwt_required
def me():
    user = user_repo.find_by_id(g.user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user.to_dict())


@app.route("/profile", methods=["PUT"])
@jwt_required
def update_profile():
    data = request.get_json(force=True) or {}
    user = user_repo.find_by_id(g.user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    if isinstance(user, Intern):
        if "gpa" in data:          user.gpa               = float(data["gpa"])
        if "skills" in data:       user.skills             = data["skills"]
        if "major" in data:        user.major              = data["major"]
        if "aboutMe" in data:      user.about_me           = data["aboutMe"]
        if "educationHistory" in data:
            user.education_history = data["educationHistory"]
    elif isinstance(user, Company):
        if "companyName" in data:  user.company_name = data["companyName"]
        if "industry" in data:     user.industry     = data["industry"]
        if "location" in data:     user.location     = data["location"]
        if "about" in data:        user.about        = data["about"]

    user_repo.save(user)
    return jsonify({"message": "Profile updated", "user": user.to_dict()})


# ── Internships ───────────────────────────────────────────────────────────────

@app.route("/internships", methods=["GET"])
def get_internships():
    keyword  = request.args.get("q", "")
    location = request.args.get("location", "")
    field    = request.args.get("field", "")

    if keyword or location or field:
        data = intern_svc.search(keyword, location, field)
    else:
        data = intern_svc.list_all()
    return jsonify(data)


@app.route("/internships", methods=["POST"])
@company_required
def post_internship():
    data = request.get_json(force=True) or {}
    result, code = intern_svc.create(g.user_id, data)
    return jsonify(result), code


@app.route("/internships/<internship_id>", methods=["DELETE"])
@company_required
def delete_internship(internship_id):
    result, code = intern_svc.delete(internship_id, g.user_id)
    return jsonify(result), code


@app.route("/internships/mine", methods=["GET"])
@company_required
def my_internships():
    repo = InternshipRepository()
    return jsonify([i.to_dict() for i in repo.find_by_company(g.user_id)])


# ── Matches ───────────────────────────────────────────────────────────────────

@app.route("/matches", methods=["GET"])
def get_matches():
    # Optionally authenticated — guests get all, interns get personalised
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        try:
            payload = jwt.decode(
                auth.split(" ", 1)[1], cfg.SECRET_KEY, algorithms=["HS256"])
            if payload["type"] in ("intern", "jobseeker", "student"):
                return jsonify(intern_svc.get_matches(payload["sub"]))
        except Exception:
            pass
    return jsonify(intern_svc.list_all())


# ── Applications ──────────────────────────────────────────────────────────────

@app.route("/apply", methods=["POST"])
@jwt_required
def apply():
    data = request.get_json(force=True) or {}
    result, code = app_svc.apply(g.user_id, data)
    return jsonify(result), code


@app.route("/applications", methods=["GET"])
@jwt_required
def get_applications():
    if g.user_type in ("company", "employer"):
        internship_id = request.args.get("internshipId")
        if not internship_id:
            return jsonify({"error": "internshipId required"}), 400
        result, code = app_svc.get_for_internship(internship_id, g.user_id)
        return jsonify(result), code
    return jsonify(app_svc.get_for_intern(g.user_id))


@app.route("/applications/<app_id>", methods=["PUT"])
@company_required
def update_application(app_id):
    data = request.get_json(force=True) or {}
    result, code = app_svc.update_status(app_id, data.get("status", ""), g.user_id)
    return jsonify(result), code


# ── File uploads ──────────────────────────────────────────────────────────────

ALLOWED_PHOTO = {"jpg", "jpeg", "png", "webp"}
ALLOWED_DOC   = {"pdf", "doc", "docx"}


def _allowed(filename: str, allowed: set) -> bool:
    return "." in filename and filename.rsplit(".", 1)[1].lower() in allowed


@app.route("/upload-photo", methods=["POST"])
@jwt_required
def upload_photo():
    if "photo" not in request.files:
        return jsonify({"error": "No file"}), 400
    f = request.files["photo"]
    if not _allowed(f.filename, ALLOWED_PHOTO):
        return jsonify({"error": "Invalid file type"}), 400

    ext      = f.filename.rsplit(".", 1)[1].lower()
    filename = secure_filename(f"{g.user_id}_photo.{ext}")
    path     = os.path.join(cfg.UPLOAD_FOLDER, filename)
    f.save(path)
    user_repo.update_photo(g.user_id, filename)
    return jsonify({"message": "Photo uploaded", "filename": filename})


@app.route("/upload-cv", methods=["POST"])
@jwt_required
def upload_cv():
    if "cv" not in request.files:
        return jsonify({"error": "No file"}), 400
    f = request.files["cv"]
    if not _allowed(f.filename, ALLOWED_DOC):
        return jsonify({"error": "Invalid file type (pdf/doc/docx only)"}), 400

    ext      = f.filename.rsplit(".", 1)[1].lower()
    filename = secure_filename(f"{g.user_id}_cv.{ext}")
    path     = os.path.join(cfg.UPLOAD_FOLDER, filename)
    f.save(path)
    user_repo.update_cv(g.user_id, filename)
    return jsonify({"message": "CV uploaded", "filename": filename})


# ── Analytics ─────────────────────────────────────────────────────────────────

@app.route("/analytics/internship/<internship_id>", methods=["GET"])
@company_required
def internship_analytics(internship_id):
    db = Database()
    row = db.execute_one(
        "SELECT COUNT(*) AS total, "
        "AVG(gpa) AS avg_gpa, "
        "SUM(CASE WHEN status='accepted' THEN 1 ELSE 0 END) AS accepted, "
        "SUM(CASE WHEN status='rejected' THEN 1 ELSE 0 END) AS rejected "
        "FROM applications WHERE internship_id=%s",
        (internship_id,)
    )
    return jsonify(row or {})


# ─────────────────────────────────────────────────────────────────────────────
# DATABASE SCHEMA BOOTSTRAP
# ─────────────────────────────────────────────────────────────────────────────

SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS users (
    id            VARCHAR(36)  PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    email         VARCHAR(180) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    user_type     ENUM('intern','company') NOT NULL,
    is_verified   TINYINT(1) DEFAULT 0,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS intern_profiles (
    user_id           VARCHAR(36) PRIMARY KEY,
    gpa               DECIMAL(4,2),
    skills            TEXT,
    major             VARCHAR(120),
    about_me          TEXT,
    education_history TEXT,
    cv_path           VARCHAR(255),
    photo_url         VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS company_profiles (
    user_id      VARCHAR(36) PRIMARY KEY,
    company_name VARCHAR(180),
    industry     VARCHAR(120),
    location     VARCHAR(180),
    about        TEXT,
    logo_url     VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS internships (
    id           VARCHAR(36)  PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    description  TEXT,
    company_id   VARCHAR(36)  NOT NULL,
    location     VARCHAR(180),
    field        VARCHAR(120),
    requirements TEXT,
    deadline     DATE,
    is_active    TINYINT(1) DEFAULT 1,
    views        INT DEFAULT 0,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (company_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS applications (
    id             VARCHAR(36) PRIMARY KEY,
    intern_id      VARCHAR(36) NOT NULL,
    internship_id  VARCHAR(36) NOT NULL,
    status         ENUM('pending','accepted','rejected') DEFAULT 'pending',
    gpa            DECIMAL(4,2),
    about_me       TEXT,
    documents      TEXT,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_application (intern_id, internship_id),
    FOREIGN KEY (intern_id)     REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
"""


def bootstrap_schema():
    db = Database()
    for stmt in SCHEMA_SQL.strip().split(";"):
        stmt = stmt.strip()
        if stmt:
            try:
                db.execute(stmt)
            except Exception as e:
                print(f"[Schema] Warning: {e}")


# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    try:
        bootstrap_schema()
        print("[Goinus] Schema ready.")
    except Exception as e:
        print(f"[Goinus] DB init failed (check MySQL is running): {e}")

    app.run(host="0.0.0.0", port=3000, debug=True)