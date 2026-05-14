"""
╔══════════════════════════════════════════════════════════════════════════════╗
║          GOINUS — Job & Internship Matching Platform                        ║
║          Flask Backend  ·  Single File  ·  Python 3.10+                    ║
║          COMPLETE PRODUCTION-READY VERSION                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

from __future__ import annotations

import os
import uuid
import bcrypt
import jwt
import datetime
import re
from abc import ABC, abstractmethod
from typing import Optional, List, Dict, Any, Tuple
from functools import wraps

try:
    from dotenv import load_dotenv
    load_dotenv()
    print("[Goinus] .env loaded.")
except ImportError:
    print("[Goinus] python-dotenv not installed — reading env vars directly.")

import mysql.connector
from mysql.connector import pooling, Error as MySQLError
from flask import Flask, request, jsonify, g, send_from_directory
from werkzeug.utils import secure_filename


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 1 ── CONFIGURATION (Singleton)
# ══════════════════════════════════════════════════════════════════════════════

class Config:
    _instance: Optional["Config"] = None

    def __new__(cls) -> "Config":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._init()
        return cls._instance

    def _init(self) -> None:
        self.SECRET_KEY = os.getenv("SECRET_KEY", "goinus_change_me_2025")
        self.JWT_EXPIRY_HOURS = int(os.getenv("JWT_EXPIRY_HOURS", "72"))
        self.UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")
        self.MAX_FILE_MB = int(os.getenv("MAX_FILE_MB", "10"))
        self.MAX_CONTENT_LENGTH = self.MAX_FILE_MB * 1024 * 1024
        self.DB_HOST = os.getenv("DB_HOST", "localhost")
        self.DB_PORT = int(os.getenv("DB_PORT", "3306"))
        self.DB_USER = os.getenv("DB_USER", "root")
        self.DB_PASSWORD = os.getenv("DB_PASSWORD", "")
        self.DB_NAME = os.getenv("DB_NAME", "goinus_db")
        self.POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "5"))

        os.makedirs(self.UPLOAD_FOLDER, exist_ok=True)

    def __repr__(self) -> str:
        return f"<Config db={self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}>"


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 2 ── DATABASE (Singleton Connection Pool)
# ══════════════════════════════════════════════════════════════════════════════

class Database:
    _instance: Optional["Database"] = None
    _pool: Optional[pooling.MySQLConnectionPool] = None

    def __new__(cls) -> "Database":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cfg = Config()
            try:
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
                    use_unicode=True,
                )
                print("[Database] Connection pool created successfully")
            except Exception as e:
                print(f"[Database] ERROR: {e}")
                raise
        return cls._instance

    def get_connection(self):
        return self._pool.get_connection()

    def execute(self, sql: str, params: tuple = ()) -> None:
        conn = None
        cur = None
        try:
            conn = self.get_connection()
            cur = conn.cursor(dictionary=True)
            cur.execute(sql, params)
            conn.commit()
        except MySQLError as e:
            if conn:
                conn.rollback()
            raise e
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()

    def execute_one(self, sql: str, params: tuple = ()) -> Optional[Dict]:
        conn = None
        cur = None
        try:
            conn = self.get_connection()
            cur = conn.cursor(dictionary=True)
            cur.execute(sql, params)
            return cur.fetchone()
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()

    def execute_many(self, sql: str, params: tuple = ()) -> List[Dict]:
        conn = None
        cur = None
        try:
            conn = self.get_connection()
            cur = conn.cursor(dictionary=True)
            cur.execute(sql, params)
            return cur.fetchall() or []
        finally:
            if cur:
                cur.close()
            if conn:
                conn.close()


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 3 ── DOMAIN MODELS
# ══════════════════════════════════════════════════════════════════════════════

class BaseModel(ABC):
    @abstractmethod
    def to_dict(self) -> Dict[str, Any]:
        pass

    @classmethod
    @abstractmethod
    def from_row(cls, row: Dict[str, Any]) -> "BaseModel":
        pass


class User(BaseModel):
    def __init__(self, id: str, name: str, email: str, password_hash: str, 
                 user_type: str, is_verified: bool = False, created_at: Any = None):
        self.id = id
        self.name = name
        self.email = email
        self.password_hash = password_hash
        self.user_type = user_type
        self.is_verified = is_verified
        self.created_at = created_at or datetime.datetime.utcnow()

    def check_password(self, raw: str) -> bool:
        return bcrypt.checkpw(raw.encode("utf-8"), self.password_hash.encode("utf-8"))

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "type": self.user_type,
            "isVerified": self.is_verified,
            "createdAt": str(self.created_at),
        }

    @classmethod
    def from_row(cls, row: Dict) -> "User":
        return cls(
            id=row["id"],
            name=row["name"],
            email=row["email"],
            password_hash=row["password_hash"],
            user_type=row["user_type"],
            is_verified=bool(row.get("is_verified", False)),
            created_at=row.get("created_at"),
        )


class Intern(User):
    def __init__(self, *args, gpa: Optional[float] = None, skills: Optional[List[str]] = None,
                 major: Optional[str] = None, about_me: Optional[str] = None,
                 education_history: Optional[str] = None, cv_path: Optional[str] = None,
                 photo_url: Optional[str] = None, **kwargs):
        super().__init__(*args, user_type="intern", **kwargs)
        self.gpa = gpa
        self.skills = skills or []
        self.major = major
        self.about_me = about_me
        self.education_history = education_history
        self.cv_path = cv_path
        self.photo_url = photo_url

    def to_dict(self) -> Dict[str, Any]:
        d = super().to_dict()
        d.update({
            "gpa": float(self.gpa) if self.gpa else None,
            "skills": self.skills,
            "major": self.major,
            "aboutMe": self.about_me,
            "educationHistory": self.education_history,
            "cvPath": self.cv_path,
            "photoUrl": self.photo_url,
        })
        return d

    @classmethod
    def from_row(cls, row: Dict) -> "Intern":
        raw_skills = row.get("skills") or ""
        skills = [s.strip() for s in raw_skills.split(",") if s.strip()]
        return cls(
            id=row["id"],
            name=row["name"],
            email=row["email"],
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
    def __init__(self, *args, company_name: Optional[str] = None, industry: Optional[str] = None,
                 location: Optional[str] = None, about: Optional[str] = None,
                 logo_url: Optional[str] = None, **kwargs):
        super().__init__(*args, user_type="company", **kwargs)
        self.company_name = company_name
        self.industry = industry
        self.location = location
        self.about = about
        self.logo_url = logo_url

    def to_dict(self) -> Dict[str, Any]:
        d = super().to_dict()
        d.update({
            "companyName": self.company_name,
            "industry": self.industry,
            "location": self.location,
            "about": self.about,
            "logoUrl": self.logo_url,
        })
        return d

    @classmethod
    def from_row(cls, row: Dict) -> "Company":
        return cls(
            id=row["id"],
            name=row["name"],
            email=row["email"],
            password_hash=row["password_hash"],
            is_verified=bool(row.get("is_verified", False)),
            created_at=row.get("created_at"),
            company_name=row.get("company_name"),
            industry=row.get("industry"),
            location=row.get("company_location") or row.get("location"),
            about=row.get("about"),
            logo_url=row.get("logo_url"),
        )


class Internship(BaseModel):
    def __init__(self, id: str, title: str, description: str, company_id: str,
                 company_name: str, location: str, field: str, requirements: List[str],
                 deadline: Any, is_active: bool = True, created_at: Any = None,
                 views: int = 0, applications_count: int = 0):
        self.id = id
        self.title = title
        self.description = description
        self.company_id = company_id
        self.company_name = company_name
        self.location = location
        self.field = field
        self.requirements = requirements
        self.deadline = deadline
        self.is_active = is_active
        self.created_at = created_at or datetime.datetime.utcnow()
        self.views = views
        self.applications_count = applications_count

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "companyId": self.company_id,
            "companyName": self.company_name,
            "location": self.location,
            "field": self.field,
            "requirements": self.requirements,
            "deadline": self.deadline.isoformat() if hasattr(self.deadline, "isoformat") else str(self.deadline),
            "isActive": self.is_active,
            "createdAt": str(self.created_at),
            "views": self.views,
            "applicationsCount": self.applications_count,
        }

    @classmethod
    def from_row(cls, row: Dict) -> "Internship":
        raw_reqs = row.get("requirements") or ""
        reqs = [r.strip() for r in raw_reqs.split(",") if r.strip()]
        return cls(
            id=row["id"],
            title=row["title"],
            description=row.get("description", ""),
            company_id=row["company_id"],
            company_name=row.get("company_name", ""),
            location=row.get("location", ""),
            field=row.get("field", ""),
            requirements=reqs,
            deadline=row["deadline"],
            is_active=bool(row.get("is_active", True)),
            created_at=row.get("created_at"),
            views=row.get("views", 0),
            applications_count=row.get("applications_count", 0),
        )


class Application(BaseModel):
    VALID_STATUSES = ("pending", "accepted", "rejected")

    def __init__(self, id: str, intern_id: str, internship_id: str, status: str = "pending",
                 gpa: Optional[float] = None, about_me: Optional[str] = None,
                 documents: Optional[List[str]] = None, created_at: Any = None):
        self.id = id
        self.intern_id = intern_id
        self.internship_id = internship_id
        self.status = status
        self.gpa = gpa
        self.about_me = about_me
        self.documents = documents or []
        self.created_at = created_at or datetime.datetime.utcnow()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "internId": self.intern_id,
            "internshipId": self.internship_id,
            "status": self.status,
            "gpa": float(self.gpa) if self.gpa else None,
            "aboutMe": self.about_me,
            "documents": self.documents,
            "createdAt": str(self.created_at),
        }

    @classmethod
    def from_row(cls, row: Dict) -> "Application":
        raw_docs = row.get("documents") or ""
        docs = [d.strip() for d in raw_docs.split(",") if d.strip()]
        return cls(
            id=row["id"],
            intern_id=row["intern_id"],
            internship_id=row["internship_id"],
            status=row.get("status", "pending"),
            gpa=row.get("gpa"),
            about_me=row.get("about_me"),
            documents=docs,
            created_at=row.get("created_at"),
        )


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 4 ── FACTORY
# ══════════════════════════════════════════════════════════════════════════════

class UserFactory:
    _INTERN_TYPES = {"intern", "jobseeker", "student"}
    _COMPANY_TYPES = {"company", "employer"}

    @classmethod
    def create(cls, user_type: str, **kwargs) -> User:
        t = user_type.lower()
        if t in cls._INTERN_TYPES:
            return Intern(**kwargs)
        if t in cls._COMPANY_TYPES:
            return Company(**kwargs)
        raise ValueError(f"Unknown user_type='{user_type}'")

    @classmethod
    def from_row(cls, row: Dict) -> User:
        t = (row.get("user_type") or "intern").lower()
        if t in cls._INTERN_TYPES:
            return Intern.from_row(row)
        return Company.from_row(row)


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 5 ── REPOSITORIES
# ══════════════════════════════════════════════════════════════════════════════

class BaseRepository(ABC):
    def __init__(self):
        self.db = Database()


class UserRepository(BaseRepository):
    _SELECT = """
        SELECT u.*, 
        ip.gpa, ip.skills, ip.major, ip.about_me, 
        ip.education_history, ip.cv_path, ip.photo_url,
        cp.company_name, cp.industry, 
        cp.location AS company_location, cp.about, cp.logo_url
        FROM users u 
        LEFT JOIN intern_profiles ip ON u.id = ip.user_id 
        LEFT JOIN company_profiles cp ON u.id = cp.user_id 
    """

    def find_by_email(self, email: str) -> Optional[User]:
        row = self.db.execute_one(self._SELECT + "WHERE u.email = %s", (email,))
        return UserFactory.from_row(row) if row else None

    def find_by_id(self, user_id: str) -> Optional[User]:
        row = self.db.execute_one(self._SELECT + "WHERE u.id = %s", (user_id,))
        return UserFactory.from_row(row) if row else None

    def save(self, user: User) -> None:
        self.db.execute(
            "INSERT INTO users (id, name, email, password_hash, user_type, is_verified) "
            "VALUES (%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE name=VALUES(name), email=VALUES(email)",
            (user.id, user.name, user.email, user.password_hash, user.user_type, user.is_verified),
        )
        if isinstance(user, Intern):
            skills_str = ",".join(user.skills or [])
            self.db.execute(
                "INSERT INTO intern_profiles (user_id, gpa, skills, major, about_me, education_history, cv_path, photo_url) "
                "VALUES (%s,%s,%s,%s,%s,%s,%s,%s) "
                "ON DUPLICATE KEY UPDATE gpa=VALUES(gpa), skills=VALUES(skills), major=VALUES(major), "
                "about_me=VALUES(about_me), education_history=VALUES(education_history), "
                "cv_path=VALUES(cv_path), photo_url=VALUES(photo_url)",
                (user.id, user.gpa, skills_str, user.major, user.about_me,
                 user.education_history, user.cv_path, user.photo_url),
            )
        elif isinstance(user, Company):
            self.db.execute(
                "INSERT INTO company_profiles (user_id, company_name, industry, location, about, logo_url) "
                "VALUES (%s,%s,%s,%s,%s,%s) "
                "ON DUPLICATE KEY UPDATE company_name=VALUES(company_name), industry=VALUES(industry), "
                "location=VALUES(location), about=VALUES(about), logo_url=VALUES(logo_url)",
                (user.id, user.company_name, user.industry, user.location, user.about, user.logo_url),
            )

    def update_photo(self, user_id: str, photo_url: str) -> None:
        self.db.execute("UPDATE intern_profiles SET photo_url=%s WHERE user_id=%s", (photo_url, user_id))

    def update_cv(self, user_id: str, cv_path: str) -> None:
        self.db.execute("UPDATE intern_profiles SET cv_path=%s WHERE user_id=%s", (cv_path, user_id))

    def all_interns(self) -> List[Intern]:
        rows = self.db.execute_many(self._SELECT + "WHERE u.user_type='intern'")
        return [UserFactory.from_row(r) for r in rows]


class InternshipRepository(BaseRepository):
    _SELECT = """
        SELECT i.*, cp.company_name,
        (SELECT COUNT(*) FROM applications a WHERE a.internship_id=i.id) AS applications_count
        FROM internships i 
        INNER JOIN company_profiles cp ON i.company_id = cp.user_id 
    """

    def find_all(self, only_active: bool = True) -> List[Internship]:
        where = "WHERE i.is_active=1 AND i.deadline >= CURDATE() " if only_active else ""
        rows = self.db.execute_many(self._SELECT + where + "ORDER BY i.created_at DESC")
        return [Internship.from_row(r) for r in rows]

    def find_by_id(self, internship_id: str) -> Optional[Internship]:
        row = self.db.execute_one(self._SELECT + "WHERE i.id=%s", (internship_id,))
        return Internship.from_row(row) if row else None

    def find_by_company(self, company_id: str) -> List[Internship]:
        rows = self.db.execute_many(self._SELECT + "WHERE i.company_id=%s ORDER BY i.created_at DESC", (company_id,))
        return [Internship.from_row(r) for r in rows]

    def search(self, keyword: str = "", location: str = "", field: str = "") -> List[Internship]:
        conds = ["i.is_active=1", "i.deadline >= CURDATE()"]
        params = []
        if keyword:
            conds.append("(i.title LIKE %s OR i.description LIKE %s OR i.requirements LIKE %s)")
            like = f"%{keyword}%"
            params += [like, like, like]
        if location:
            conds.append("i.location LIKE %s")
            params.append(f"%{location}%")
        if field:
            conds.append("i.field LIKE %s")
            params.append(f"%{field}%")
        where = "WHERE " + " AND ".join(conds)
        rows = self.db.execute_many(self._SELECT + where + " ORDER BY i.created_at DESC", tuple(params))
        return [Internship.from_row(r) for r in rows]

    def save(self, internship: Internship) -> None:
        reqs_str = ",".join(internship.requirements)
        self.db.execute(
            "INSERT INTO internships (id, title, description, company_id, location, field, requirements, deadline, is_active) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE title=VALUES(title), description=VALUES(description), "
            "location=VALUES(location), field=VALUES(field), requirements=VALUES(requirements), "
            "deadline=VALUES(deadline), is_active=VALUES(is_active)",
            (internship.id, internship.title, internship.description, internship.company_id,
             internship.location, internship.field, reqs_str, internship.deadline, internship.is_active),
        )

    def delete(self, internship_id: str) -> None:
        self.db.execute("DELETE FROM internships WHERE id=%s", (internship_id,))

    def increment_views(self, internship_id: str) -> None:
        self.db.execute("UPDATE internships SET views = views + 1 WHERE id=%s", (internship_id,))


class ApplicationRepository(BaseRepository):
    def find_by_intern(self, intern_id: str) -> List[Application]:
        rows = self.db.execute_many("SELECT * FROM applications WHERE intern_id=%s ORDER BY created_at DESC", (intern_id,))
        return [Application.from_row(r) for r in rows]

    def find_by_internship(self, internship_id: str) -> List[Application]:
        rows = self.db.execute_many("SELECT * FROM applications WHERE internship_id=%s ORDER BY created_at DESC", (internship_id,))
        return [Application.from_row(r) for r in rows]

    def find_by_id(self, app_id: str) -> Optional[Application]:
        row = self.db.execute_one("SELECT * FROM applications WHERE id=%s", (app_id,))
        return Application.from_row(row) if row else None

    def exists(self, intern_id: str, internship_id: str) -> bool:
        row = self.db.execute_one("SELECT id FROM applications WHERE intern_id=%s AND internship_id=%s", (intern_id, internship_id))
        return row is not None

    def save(self, app: Application) -> None:
        docs_str = ",".join(app.documents or [])
        self.db.execute(
            "INSERT INTO applications (id, intern_id, internship_id, status, gpa, about_me, documents) "
            "VALUES (%s,%s,%s,%s,%s,%s,%s) "
            "ON DUPLICATE KEY UPDATE status=VALUES(status)",
            (app.id, app.intern_id, app.internship_id, app.status, app.gpa, app.about_me, docs_str),
        )

    def update_status(self, app_id: str, status: str) -> None:
        self.db.execute("UPDATE applications SET status=%s WHERE id=%s", (status, app_id))


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 6 ── MATCHING STRATEGY
# ══════════════════════════════════════════════════════════════════════════════

class MatchingStrategy(ABC):
    @abstractmethod
    def score(self, intern: Intern, internship: Internship) -> int:
        pass

    def match(self, intern: Intern, internships: List[Internship]) -> List[Dict[str, Any]]:
        results = [{"score": self.score(intern, job), "internship": job} for job in internships]
        results.sort(key=lambda x: x["score"], reverse=True)
        return results


class SkillsAndGpaStrategy(MatchingStrategy):
    def score(self, intern: Intern, internship: Internship) -> int:
        intern_skills = {s.lower() for s in (intern.skills or [])}
        req_skills = {r.lower() for r in internship.requirements}
        skill_score = (len(intern_skills & req_skills) / len(req_skills)) * 60 if req_skills else 30
        gpa_score = min((intern.gpa or 0.0) / 4.0 * 40, 40)
        return round(skill_score + gpa_score)


class KeywordMatchingStrategy(MatchingStrategy):
    def score(self, intern: Intern, internship: Internship) -> int:
        intern_kw = set((intern.major or "").lower().split())
        intern_kw |= {s.lower() for s in (intern.skills or [])}
        job_kw = set(internship.field.lower().split())
        for req in internship.requirements:
            job_kw |= set(req.lower().split())
        overlap = len(intern_kw & job_kw)
        return min(overlap * 15, 95)


class MatchingContext:
    def __init__(self, strategy: Optional[MatchingStrategy] = None):
        self._strategy = strategy or SkillsAndGpaStrategy()

    def get_matches(self, intern: Intern, internships: List[Internship]) -> List[Dict[str, Any]]:
        return self._strategy.match(intern, internships)


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 7 ── SERVICES
# ══════════════════════════════════════════════════════════════════════════════

class AuthService:
    def __init__(self):
        self.user_repo = UserRepository()
        self.cfg = Config()

    @staticmethod
    def _hash_password(raw: str) -> str:
        return bcrypt.hashpw(raw.encode("utf-8"), bcrypt.gensalt(rounds=12)).decode()

    def _make_token(self, user: User) -> str:
        payload = {
            "sub": user.id,
            "type": user.user_type,
            "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=self.cfg.JWT_EXPIRY_HOURS),
        }
        return jwt.encode(payload, self.cfg.SECRET_KEY, algorithm="HS256")

    def register(self, data: Dict) -> Tuple[Dict, int]:
        email = (data.get("email") or "").strip().lower()
        if not re.match(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
            return {"error": "Invalid email address"}, 400
        if not data.get("password") or len(data.get("password", "")) < 6:
            return {"error": "Password must be at least 6 characters"}, 400
        if self.user_repo.find_by_email(email):
            return {"error": "Email already registered"}, 409

        user_type = (data.get("type") or "intern").lower()
        uid = str(uuid.uuid4())
        pwd_hash = self._hash_password(data["password"])

        if user_type in UserFactory._COMPANY_TYPES:
            user = Company(
                id=uid, name=data.get("name", "").strip(), email=email, password_hash=pwd_hash,
                company_name=data.get("company"), industry=data.get("industry"), location=data.get("location"),
            )
        else:
            skills = data.get("skills") or []
            if isinstance(skills, str):
                skills = [s.strip() for s in skills.split(",") if s.strip()]
            user = Intern(
                id=uid, name=data.get("name", "").strip(), email=email, password_hash=pwd_hash,
                skills=skills, major=data.get("major"), gpa=float(data["gpa"]) if data.get("gpa") else None,
            )

        self.user_repo.save(user)
        return {"token": self._make_token(user), "user": user.to_dict()}, 201

    def login(self, email: str, password: str) -> Tuple[Dict, int]:
        email = (email or "").strip().lower()
        user = self.user_repo.find_by_email(email)
        if not user or not user.check_password(password):
            return {"error": "Invalid email or password"}, 401
        return {"token": self._make_token(user), "user": user.to_dict()}, 200


class InternshipService:
    def __init__(self):
        self.repo = InternshipRepository()
        self.user_repo = UserRepository()

    def create(self, company_id: str, data: Dict) -> Tuple[Dict, int]:
        required = ("title", "description", "location", "field", "deadline")
        missing = [f for f in required if not data.get(f)]
        if missing:
            return {"error": f"Missing fields: {', '.join(missing)}"}, 400

        reqs = data.get("requirements") or []
        if isinstance(reqs, str):
            reqs = [r.strip() for r in reqs.split(",") if r.strip()]

        try:
            deadline = datetime.datetime.fromisoformat(data["deadline"].replace("Z", "")).date()
        except (ValueError, AttributeError):
            return {"error": "Invalid deadline format"}, 400

        internship = Internship(
            id=str(uuid.uuid4()),
            title=data["title"].strip(),
            description=data.get("description", "").strip(),
            company_id=company_id,
            company_name="",
            location=data.get("location", "").strip(),
            field=data.get("field", "").strip(),
            requirements=reqs,
            deadline=deadline,
        )
        self.repo.save(internship)
        return {"id": internship.id, "message": "Internship posted successfully"}, 201

    def list_all(self) -> List[Dict]:
        return [i.to_dict() for i in self.repo.find_all()]

    def search(self, keyword: str, location: str, field: str) -> List[Dict]:
        return [i.to_dict() for i in self.repo.search(keyword, location, field)]

    def get_matches(self, user_id: str) -> List[Dict]:
        user = self.user_repo.find_by_id(user_id)
        all_jobs = self.repo.find_all()

        if not isinstance(user, Intern):
            jobs = [j.to_dict() for j in all_jobs]
            for job in jobs:
                job["matchScore"] = 50
            return jobs

        strategy = SkillsAndGpaStrategy() if (user.skills or user.gpa) else KeywordMatchingStrategy()
        ctx = MatchingContext(strategy)
        matches = ctx.get_matches(user, all_jobs)
        return [{**m["internship"].to_dict(), "matchScore": m["score"]} for m in matches]

    def delete(self, internship_id: str, company_id: str) -> Tuple[Dict, int]:
        job = self.repo.find_by_id(internship_id)
        if not job:
            return {"error": "Internship not found"}, 404
        if job.company_id != company_id:
            return {"error": "Forbidden"}, 403
        self.repo.delete(internship_id)
        return {"message": "Internship deleted"}, 200


class ApplicationService:
    def __init__(self):
        self.app_repo = ApplicationRepository()
        self.job_repo = InternshipRepository()

    def apply(self, intern_id: str, data: Dict) -> Tuple[Dict, int]:
        internship_id = data.get("internshipId")
        if not internship_id:
            return {"error": "internshipId required"}, 400

        job = self.job_repo.find_by_id(internship_id)
        if not job:
            return {"error": "Internship not found"}, 404
        if not job.is_active:
            return {"error": "No longer accepting applications"}, 400
        if self.app_repo.exists(intern_id, internship_id):
            return {"error": "Already applied"}, 409

        app = Application(
            id=str(uuid.uuid4()),
            intern_id=intern_id,
            internship_id=internship_id,
            gpa=float(data["gpa"]) if data.get("gpa") else None,
            about_me=data.get("aboutMe"),
            documents=data.get("documents") or [],
        )
        self.app_repo.save(app)
        return {"message": "Application submitted", "id": app.id}, 201

    def get_for_intern(self, intern_id: str) -> List[Dict]:
        return [a.to_dict() for a in self.app_repo.find_by_intern(intern_id)]

    def get_for_internship(self, internship_id: str, company_id: str) -> Tuple[Any, int]:
        job = self.job_repo.find_by_id(internship_id)
        if not job:
            return {"error": "Not found"}, 404
        if job.company_id != company_id:
            return {"error": "Forbidden"}, 403
        return [a.to_dict() for a in self.app_repo.find_by_internship(internship_id)], 200

    def update_status(self, app_id: str, status: str, company_id: str) -> Tuple[Dict, int]:
        if status not in Application.VALID_STATUSES:
            return {"error": f"Invalid status"}, 400
        app = self.app_repo.find_by_id(app_id)
        if not app:
            return {"error": "Not found"}, 404
        job = self.job_repo.find_by_id(app.internship_id)
        if not job or job.company_id != company_id:
            return {"error": "Forbidden"}, 403
        self.app_repo.update_status(app_id, status)
        return {"message": f"Application {status}"}, 200


# ══════════════════════════════════════════════════════════════════════════════
#  SECTION 8 ── FLASK APP
# ══════════════════════════════════════════════════════════════════════════════

app = Flask(__name__)
cfg = Config()
app.config["MAX_CONTENT_LENGTH"] = cfg.MAX_CONTENT_LENGTH

auth_svc = AuthService()
intern_svc = InternshipService()
app_svc = ApplicationService()
user_repo = UserRepository()
job_repo = InternshipRepository()


# ── CORS ──────────────────────────────────────────────────────────────────────

@app.after_request
def add_cors_headers(response):
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    return response


@app.route("/<path:path>", methods=["OPTIONS"])
def options_preflight(path):
    return jsonify({}), 200


# ── JWT ──────────────────────────────────────────────────────────────────────

def jwt_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get("Authorization", "")
        if not auth.startswith("Bearer "):
            return jsonify({"error": "Authorization required"}), 401
        token = auth.split(" ", 1)[1]
        try:
            payload = jwt.decode(token, cfg.SECRET_KEY, algorithms=["HS256"])
            g.user_id = payload["sub"]
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
            return jsonify({"error": "Company account required"}), 403
        return f(*args, **kwargs)
    return decorated


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route("/", methods=["GET"])
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "app": "Goinus API", "version": "2.0.0"})


@app.route("/register", methods=["POST"])
def register():
    data = request.get_json(force=True, silent=True) or {}
    result, code = auth_svc.register(data)
    return jsonify(result), code


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json(force=True, silent=True) or {}
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
    data = request.get_json(force=True, silent=True) or {}
    user = user_repo.find_by_id(g.user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404

    if isinstance(user, Intern):
        if "gpa" in data:
            user.gpa = float(data["gpa"]) if data["gpa"] else None
        if "skills" in data:
            user.skills = data["skills"] if isinstance(data["skills"], list) else [s.strip() for s in str(data["skills"]).split(",") if s.strip()]
        if "major" in data:
            user.major = data["major"]
        if "aboutMe" in data:
            user.about_me = data["aboutMe"]
        if "educationHistory" in data:
            user.education_history = data["educationHistory"]
    elif isinstance(user, Company):
        if "companyName" in data:
            user.company_name = data["companyName"]
        if "industry" in data:
            user.industry = data["industry"]
        if "location" in data:
            user.location = data["location"]
        if "about" in data:
            user.about = data["about"]

    user_repo.save(user)
    return jsonify({"message": "Profile updated", "user": user.to_dict()})


@app.route("/internships", methods=["GET"])
def get_internships():
    keyword = request.args.get("q", "").strip()
    location = request.args.get("location", "").strip()
    field = request.args.get("field", "").strip()
    data = intern_svc.search(keyword, location, field) if (keyword or location or field) else intern_svc.list_all()
    return jsonify(data)


@app.route("/internships/<internship_id>", methods=["GET"])
def get_internship(internship_id):
    job = job_repo.find_by_id(internship_id)
    if not job:
        return jsonify({"error": "Not found"}), 404
    job_repo.increment_views(internship_id)
    return jsonify(job.to_dict())


@app.route("/internships", methods=["POST"])
@company_required
def post_internship():
    data = request.get_json(force=True, silent=True) or {}
    result, code = intern_svc.create(g.user_id, data)
    return jsonify(result), code


@app.route("/internships/mine", methods=["GET"])
@company_required
def my_internships():
    return jsonify([i.to_dict() for i in job_repo.find_by_company(g.user_id)])


@app.route("/matches", methods=["GET"])
def get_matches():
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        try:
            payload = jwt.decode(auth.split(" ", 1)[1], cfg.SECRET_KEY, algorithms=["HS256"])
            if payload["type"] in ("intern", "jobseeker", "student"):
                return jsonify(intern_svc.get_matches(payload["sub"]))
        except jwt.PyJWTError:
            pass
    jobs = intern_svc.list_all()
    for job in jobs:
        job["matchScore"] = 50
    return jsonify(jobs)


@app.route("/apply", methods=["POST"])
@jwt_required
def apply():
    data = request.get_json(force=True, silent=True) or {}
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
    data = request.get_json(force=True, silent=True) or {}
    result, code = app_svc.update_status(app_id, data.get("status", ""), g.user_id)
    return jsonify(result), code


# ── File Uploads ──────────────────────────────────────────────────────────────

ALLOWED_PHOTO = {"jpg", "jpeg", "png", "webp"}
ALLOWED_DOC = {"pdf", "doc", "docx"}


def _ext(filename: str) -> str:
    return filename.rsplit(".", 1)[-1].lower() if "." in filename else ""


@app.route("/upload-photo", methods=["POST"])
@jwt_required
def upload_photo():
    if "photo" not in request.files:
        return jsonify({"error": "No file"}), 400
    f = request.files["photo"]
    if not f.filename or _ext(f.filename) not in ALLOWED_PHOTO:
        return jsonify({"error": "Invalid format. Use: jpg, jpeg, png, webp"}), 400

    f.seek(0, 2)
    size = f.tell()
    f.seek(0)
    if size > cfg.MAX_CONTENT_LENGTH:
        return jsonify({"error": f"File exceeds {cfg.MAX_FILE_MB} MB"}), 413

    filename = secure_filename(f"{g.user_id}_photo.{_ext(f.filename)}")
    path = os.path.join(cfg.UPLOAD_FOLDER, filename)
    f.save(path)
    user_repo.update_photo(g.user_id, filename)
    return jsonify({"message": "Photo uploaded", "filename": filename, "photoUrl": filename})


@app.route("/upload-cv", methods=["POST"])
@jwt_required
def upload_cv():
    if "cv" not in request.files:
        return jsonify({"error": "No file"}), 400
    f = request.files["cv"]
    if not f.filename or _ext(f.filename) not in ALLOWED_DOC:
        return jsonify({"error": "Invalid format. Use: pdf, doc, docx"}), 400

    f.seek(0, 2)
    size = f.tell()
    f.seek(0)
    if size > cfg.MAX_CONTENT_LENGTH:
        return jsonify({"error": f"File exceeds {cfg.MAX_FILE_MB} MB"}), 413

    filename = secure_filename(f"{g.user_id}_cv.{_ext(f.filename)}")
    path = os.path.join(cfg.UPLOAD_FOLDER, filename)
    f.save(path)
    user_repo.update_cv(g.user_id, filename)
    return jsonify({"message": "CV uploaded", "filename": filename})


@app.route("/uploads/<filename>", methods=["GET"])
@jwt_required
def serve_upload(filename):
    return send_from_directory(cfg.UPLOAD_FOLDER, filename)


# ── Error Handlers ────────────────────────────────────────────────────────────

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Endpoint not found"}), 404


@app.errorhandler(413)
def file_too_large(e):
    return jsonify({"error": f"File exceeds {cfg.MAX_FILE_MB} MB limit"}), 413


@app.errorhandler(500)
def internal_error(e):
    return jsonify({"error": "Internal server error"}), 500


# ══════════════════════════════════════════════════════════════════════════════
#  ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

def bootstrap_schema():
    db = Database()
    schemas = [
        """
        CREATE TABLE IF NOT EXISTS users (
            id VARCHAR(36) PRIMARY KEY,
            name VARCHAR(120) NOT NULL,
            email VARCHAR(180) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            user_type ENUM('intern','company') NOT NULL,
            is_verified TINYINT(1) DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_email (email),
            INDEX idx_user_type (user_type)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """,
        """
        CREATE TABLE IF NOT EXISTS intern_profiles (
            user_id VARCHAR(36) PRIMARY KEY,
            gpa DECIMAL(4,2),
            skills TEXT,
            major VARCHAR(120),
            about_me TEXT,
            education_history TEXT,
            cv_path VARCHAR(255),
            photo_url VARCHAR(255),
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """,
        """
        CREATE TABLE IF NOT EXISTS company_profiles (
            user_id VARCHAR(36) PRIMARY KEY,
            company_name VARCHAR(180),
            industry VARCHAR(120),
            location VARCHAR(180),
            about TEXT,
            logo_url VARCHAR(255),
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """,
        """
        CREATE TABLE IF NOT EXISTS internships (
            id VARCHAR(36) PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            company_id VARCHAR(36) NOT NULL,
            location VARCHAR(180),
            field VARCHAR(120),
            requirements TEXT,
            deadline DATE,
            is_active TINYINT(1) DEFAULT 1,
            views INT DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_company (company_id),
            INDEX idx_active (is_active),
            INDEX idx_deadline (deadline),
            FOREIGN KEY (company_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """,
        """
        CREATE TABLE IF NOT EXISTS applications (
            id VARCHAR(36) PRIMARY KEY,
            intern_id VARCHAR(36) NOT NULL,
            internship_id VARCHAR(36) NOT NULL,
            status ENUM('pending','accepted','rejected') DEFAULT 'pending',
            gpa DECIMAL(4,2),
            about_me TEXT,
            documents TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY uq_application (intern_id, internship_id),
            INDEX idx_intern (intern_id),
            INDEX idx_internship (internship_id),
            FOREIGN KEY (intern_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        """,
    ]
    for schema in schemas:
        try:
            db.execute(schema)
        except MySQLError as e:
            print(f"[Schema] Warning: {e}")
    print("[Goinus] Database schema ready.")


if __name__ == "__main__":
    print("=" * 60)
    print("  Goinus API — Starting up")
    print(f"  Config: {Config()}")
    print("=" * 60)
    
    try:
        bootstrap_schema()
    except Exception as e:
        print(f"[Goinus] DB init failed: {e}")
        print("[Goinus] Make sure MySQL is running and credentials are correct")
    
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "3000")), debug=os.getenv("FLASK_DEBUG", "1") == "1")