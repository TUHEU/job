const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { User, JobSeeker, Employer, Internship, InternshipApplication } = require('./models');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'your-secret-key'; // In production, use environment variable

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const sanitizeUser = (user) => {
    if (!user) return null;
    const { password, ...safeUser } = user;
    return safeUser;
};

// Multer setup for file uploads
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage });

// Middleware to verify JWT
const authenticateToken = (req, res, next) => {
    const authHeader = req.header('Authorization');
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'Access denied' });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: 'Invalid token' });
        req.user = user;
        next();
    });
};

// Routes

// Register
app.post('/register', async(req, res) => {
    const { name, email, password, type, company, skills } = req.body;

    if (User.findByEmail(email)) {
        return res.status(400).json({ message: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const id = uuidv4();

    let user;
    if (type === 'jobseeker') {
        user = new JobSeeker(id, name, email, hashedPassword, skills || []);
    } else if (type === 'employer') {
        user = new Employer(id, name, email, hashedPassword, company);
    } else {
        return res.status(400).json({ message: 'Invalid user type' });
    }

    user.save();
    const token = jwt.sign({ id: user.id, type: user.type }, JWT_SECRET);
    res.status(201).json({
        message: 'User registered successfully',
        token,
        user: sanitizeUser(user),
    });
});

// Login
app.post('/login', async(req, res) => {
    const { email, password } = req.body;
    const user = User.findByEmail(email);
    if (!user || !(await bcrypt.compare(password, user.password))) {
        return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, type: user.type }, JWT_SECRET);
    res.json({ token, user: sanitizeUser(user) });
});

// Upload CV
app.post('/upload-cv', authenticateToken, upload.single('cv'), (req, res) => {
    if (req.user.type !== 'jobseeker') {
        return res.status(403).json({ message: 'Only job seekers can upload CVs' });
    }

    const user = User.findById(req.user.id);
    user.cvPath = req.file.path;
    // Update user in JSON
    const users = User.getAll();
    const index = users.findIndex(u => u.id === req.user.id);
    users[index] = user;
    require('fs').writeFileSync(path.join(__dirname, 'data', 'users.json'), JSON.stringify(users, null, 2));

    res.json({ success: true, message: 'CV uploaded successfully', user: user });
});

// Get internships
app.get('/internships', (req, res) => {
    const internships = Internship.getAll();
    res.json(internships);
});

// Post internship
app.post('/internships', authenticateToken, (req, res) => {
    if (req.user.type !== 'employer') {
        return res.status(403).json({ message: 'Only employers can post internships' });
    }

    const employer = User.findById(req.user.id);
    const { title, description, requirements, location, field, deadline } = req.body;
    const id = uuidv4();
    const internship = new Internship(
        id,
        title,
        description,
        req.user.id,
        employer?.company || employer?.name || 'Employer',
        requirements || [],
        location || '',
        field || '',
        deadline,
    );
    internship.save();
    res.status(201).json(internship);
});

// Apply for internship
app.post('/apply', (req, res) => {
    const authHeader = req.header('Authorization');
    const token = authHeader && authHeader.split(' ')[1];
    let applicantId = 'guest';
    if (token) {
        try {
            const payload = jwt.verify(token, JWT_SECRET);
            applicantId = payload.id;
        } catch (err) {
            applicantId = 'guest';
        }
    }

    const { internshipId, gpa, aboutMe, documents } = req.body;
    const id = uuidv4();
    const application = new InternshipApplication(id, applicantId, internshipId, 'pending', gpa, aboutMe, documents || []);
    application.save();
    res.status(201).json({ message: 'Application submitted' });
});

// Get applications for employer
app.get('/applications', authenticateToken, (req, res) => {
    if (req.user.type !== 'employer') {
        return res.status(403).json({ message: 'Only employers can view applications' });
    }

    const internships = Internship.findByEmployer(req.user.id);
    const applications = [];
    internships.forEach(internship => {
        applications.push(...InternshipApplication.findByInternship(internship.id));
    });
    res.json(applications);
});

// Update application status
app.put('/applications/:id', authenticateToken, (req, res) => {
    if (req.user.type !== 'employer') {
        return res.status(403).json({ message: 'Only employers can update applications' });
    }

    const { status } = req.body;
    InternshipApplication.updateStatus(req.params.id, status);
    res.json({ message: 'Status updated' });
});

// Get matches for job seeker or guest
app.get('/matches', (req, res) => {
    const authHeader = req.header('Authorization');
    const token = authHeader && authHeader.split(' ')[1];
    let skills = ['Flutter', 'Dart', 'Mobile Development'];

    if (token) {
        try {
            const payload = jwt.verify(token, JWT_SECRET);
            const user = User.findById(payload.id);
            if (user && user.skills) {
                skills = user.skills;
            }
        } catch (err) {
            // Keep default guest skills
        }
    }

    const internships = Internship.getAll();
    const matches = internships.filter(internship => {
        return internship.requirements.some(req => skills.includes(req));
    });
    res.json(matches);
});

// Upload photo
app.post('/upload-photo', upload.single('photo'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ message: 'No file uploaded' });
    }
    res.json({
        success: true,
        message: 'Photo uploaded successfully',
        filename: req.file.filename,
        path: `/uploads/${req.file.filename}`
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
