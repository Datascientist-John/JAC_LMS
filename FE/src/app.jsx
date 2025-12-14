import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [activeTab, setActiveTab] = useState('courses');
  const [courses, setCourses] = useState([]);
  const [user, setUser] = useState(null);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [lessons, setLessons] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [loading, setLoading] = useState(true);

  // Fetch user profile
  useEffect(() => {
    fetch('/api/walker/GetUserProfile', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: 'user123' })
    })
      .then(res => res.json())
      .then(data => setUser(data.user))
      .catch(err => console.error('Error fetching user:', err));
  }, []);

  // Fetch courses
  useEffect(() => {
    setLoading(true);
    fetch('/api/walker/GetCourses', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    })
      .then(res => res.json())
      .then(data => {
        setCourses(data.courses);
        setLoading(false);
      })
      .catch(err => {
        console.error('Error fetching courses:', err);
        setLoading(false);
      });
  }, []);

  // View course details
  const viewCourse = (courseId) => {
    setSelectedCourse(courseId);
    setActiveTab('course-detail');

    // Fetch lessons
    fetch('/api/walker/GetLessons', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ course_id: courseId })
    })
      .then(res => res.json())
      .then(data => setLessons(data.lessons))
      .catch(err => console.error('Error fetching lessons:', err));

    // Fetch assignments
    fetch('/api/walker/GetAssignments', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ course_id: courseId })
    })
      .then(res => res.json())
      .then(data => setAssignments(data.assignments))
      .catch(err => console.error('Error fetching assignments:', err));
  };

  // Enroll in course
  const enrollInCourse = (courseId) => {
    fetch('/api/walker/EnrollCourse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: 'user123', course_id: courseId })
    })
      .then(res => res.json())
      .then(data => {
        alert(data.message);
      })
      .catch(err => console.error('Error enrolling:', err));
  };

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="header-content">
          <h1>🎓 Learning Management System</h1>
          {user && (
            <div className="user-info">
              <img src={user.avatar} alt={user.name} className="avatar" />
              <span>{user.name}</span>
            </div>
          )}
        </div>
      </header>

      {/* Navigation */}
      <nav className="nav">
        <button
          className={activeTab === 'courses' ? 'active' : ''}
          onClick={() => setActiveTab('courses')}
        >
          All Courses
        </button>
        <button
          className={activeTab === 'my-courses' ? 'active' : ''}
          onClick={() => setActiveTab('my-courses')}
        >
          My Courses
        </button>
        <button
          className={activeTab === 'profile' ? 'active' : ''}
          onClick={() => setActiveTab('profile')}
        >
          Profile
        </button>
      </nav>

      {/* Main Content */}
      <main className="main-content">
        {loading ? (
          <div className="loading">Loading courses...</div>
        ) : (
          <>
            {/* All Courses Tab */}
            {activeTab === 'courses' && (
              <div className="courses-grid">
                <h2>Available Courses</h2>
                <div className="grid">
                  {courses.map(course => (
                    <div key={course.id} className="course-card">
                      <h3>{course.title}</h3>
                      <p>{course.description}</p>
                      <div className="course-meta">
                        <span>👥 {course.enrolled_count} students</span>
                      </div>
                      <div className="course-actions">
                        <button 
                          onClick={() => viewCourse(course.id)}
                          className="btn-primary"
                        >
                          View Details
                        </button>
                        <button 
                          onClick={() => enrollInCourse(course.id)}
                          className="btn-secondary"
                        >
                          Enroll
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* My Courses Tab */}
            {activeTab === 'my-courses' && user && (
              <div className="my-courses">
                <h2>My Enrolled Courses</h2>
                <div className="grid">
                  {courses
                    .filter(c => user.enrolled_courses.includes(c.id))
                    .map(course => (
                      <div key={course.id} className="course-card enrolled">
                        <h3>{course.title}</h3>
                        <p>{course.description}</p>
                        <button 
                          onClick={() => viewCourse(course.id)}
                          className="btn-primary"
                        >
                          Continue Learning
                        </button>
                      </div>
                    ))}
                </div>
              </div>
            )}

            {/* Course Detail Tab */}
            {activeTab === 'course-detail' && selectedCourse && (
              <div className="course-detail">
                <button 
                  onClick={() => setActiveTab('courses')}
                  className="back-btn"
                >
                  ← Back to Courses
                </button>
                
                <h2>Course Content</h2>
                
                <div className="detail-section">
                  <h3>📚 Lessons</h3>
                  <div className="lessons-list">
                    {lessons.map(lesson => (
                      <div key={lesson.id} className="lesson-item">
                        <div>
                          <h4>{lesson.order}. {lesson.title}</h4>
                          <p>{lesson.content}</p>
                        </div>
                        <span className="duration">{lesson.duration}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div className="detail-section">
                  <h3>📝 Assignments</h3>
                  <div className="assignments-list">
                    {assignments.map(assignment => (
                      <div key={assignment.id} className="assignment-item">
                        <div>
                          <h4>{assignment.title}</h4>
                          <p>{assignment.description}</p>
                          <span className="due-date">Due: {assignment.due_date}</span>
                        </div>
                        <div className="assignment-meta">
                          <span className="points">{assignment.points} pts</span>
                          <span className={`status ${assignment.status}`}>
                            {assignment.status.replace('_', ' ')}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Profile Tab */}
            {activeTab === 'profile' && user && (
              <div className="profile">
                <h2>My Profile</h2>
                <div className="profile-card">
                  <img src={user.avatar} alt={user.name} className="profile-avatar" />
                  <h3>{user.name}</h3>
                  <p>{user.email}</p>
                  <p className="role">Role: {user.role}</p>
                  <div className="profile-stats">
                    <div className="stat">
                      <strong>{user.enrolled_courses.length}</strong>
                      <span>Enrolled Courses</span>
                    </div>
                    <div className="stat">
                      <strong>{user.completed_courses.length}</strong>
                      <span>Completed</span>
                    </div>
                  </div>
                </div>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default App;