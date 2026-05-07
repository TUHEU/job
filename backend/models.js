const fs = require('fs');
const path = require('path');

class User {
    constructor(id, name, email, password, type) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.password = password;
        this.type = type; // 'jobseeker' or 'employer'
    }

    static save(user) {
        const users = User.getAll();
        users.push(user);
        fs.writeFileSync(path.join(__dirname, 'data', 'users.json'), JSON.stringify(users, null, 2));
    }

    static getAll() {
        try {
            const data = fs.readFileSync(path.join(__dirname, 'data', 'users.json'), 'utf8');
            return JSON.parse(data);
        } catch (err) {
            return [];
        }
    }

    static findByEmail(email) {
        const users = User.getAll();
        return users.find(user => user.email === email);
    }

    static findById(id) {
        const users = User.getAll();
        return users.find(user => user.id === id);
    }
}

class JobSeeker extends User {
    constructor(id, name, email, password, skills = [], cvPath = null) {
        super(id, name, email, password, 'jobseeker');
        this.skills = skills;
        this.cvPath = cvPath;
    }

    save() {
        User.save(this);
    }
}

class Employer extends User {
    constructor(id, name, email, password, company) {
        super(id, name, email, password, 'employer');
        this.company = company;
    }

    save() {
        User.save(this);
    }
}

class Internship {
    constructor(id, title, description, companyId, companyName, requirements = [], location = '', field = '', deadline = null) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.companyId = companyId;
        this.companyName = companyName;
        this.requirements = requirements;
        this.location = location;
        this.field = field;
        this.deadline = deadline;
    }

    static save(internship) {
        const internships = Internship.getAll();
        internships.push(internship);
        fs.writeFileSync(path.join(__dirname, 'data', 'internships.json'), JSON.stringify(internships, null, 2));
    }

    static getAll() {
        try {
            const data = fs.readFileSync(path.join(__dirname, 'data', 'internships.json'), 'utf8');
            return JSON.parse(data);
        } catch (err) {
            return [];
        }
    }

    static findById(id) {
        const internships = Internship.getAll();
        return internships.find(internship => internship.id === id);
    }

    static findByEmployer(employerId) {
        const internships = Internship.getAll();
        return internships.filter(internship => internship.companyId === employerId);
    }
}

class InternshipApplication {
    constructor(id, jobSeekerId, internshipId, status = 'pending', gpa = null, aboutMe = '', documents = []) {
        this.id = id;
        this.jobSeekerId = jobSeekerId;
        this.internshipId = internshipId;
        this.status = status;
        this.gpa = gpa;
        this.aboutMe = aboutMe;
        this.documents = documents;
    }

    static save(application) {
        const applications = InternshipApplication.getAll();
        applications.push(application);
        fs.writeFileSync(path.join(__dirname, 'data', 'applications.json'), JSON.stringify(applications, null, 2));
    }

    static getAll() {
        try {
            const data = fs.readFileSync(path.join(__dirname, 'data', 'applications.json'), 'utf8');
            return JSON.parse(data);
        } catch (err) {
            return [];
        }
    }

    static findByJobSeeker(jobSeekerId) {
        const applications = InternshipApplication.getAll();
        return applications.filter(app => app.jobSeekerId === jobSeekerId);
    }

    static findByInternship(internshipId) {
        const applications = InternshipApplication.getAll();
        return applications.filter(app => app.internshipId === internshipId);
    }

    static findById(id) {
        const applications = InternshipApplication.getAll();
        return applications.find(app => app.id === id);
    }

    static updateStatus(id, status) {
        const applications = InternshipApplication.getAll();
        const app = applications.find(a => a.id === id);
        if (app) {
            app.status = status;
            fs.writeFileSync(path.join(__dirname, 'data', 'applications.json'), JSON.stringify(applications, null, 2));
        }
    }
}

module.exports = { User, JobSeeker, Employer, Internship, InternshipApplication };