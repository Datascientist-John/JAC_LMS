Main App Component for the Learning Platform Frontend
File: client/App.jac
"""

import { useState, useEffect } from 'react';

# Component imports (assuming these are separate files)
# import { Navbar } from './components/Navbar';
# import { Dashboard } from './components/Dashboard';
# import { LessonView } from './components/LessonView';
# import { QuizView } from './components/QuizView';
# import { SkillMap } from './components/SkillMap';

# Main App Component
export function App() {
    # State management
    const [currentUser, setCurrentUser] = useState(null);
    const [currentView, setCurrentView] = useState('dashboard');
    const [selectedConcept, setSelectedConcept] = useState(null);
    const [userProgress, setUserProgress] = useState([]);
    const [loading, setLoading] = useState(true);
    
    # Initialize user session on mount
    useEffect(() => {
        const userId = localStorage.getItem('userId');
        if (userId) {
            loadUserData(userId);
        } else {
            # For demo, create a default user
            const newUserId = 'user_' + Date.now();
            registerNewUser(newUserId, 'Demo User', 'demo@example.com');
        }
    }, []);
    
    # Load user data from backend
    async function loadUserData(userId) {
        setLoading(true);
        
        try {
            # Call Jaseci API endpoint
            const response = await fetch('/walker/api_get_progress', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user_id: userId
                })
            });
            
            const result = await response.json();
            
            if (result.user_id) {
                setCurrentUser({
                    userId: result.user_id,
                    name: result.name,
                    totalScore: result.total_score
                });
                setUserProgress(result.progress || []);
                localStorage.setItem('userId', userId);
            }
        } catch (error) {
            console.error('Error loading user data:', error);
        } finally {
            setLoading(false);
        }
    }
    
    # Register a new user
    async function registerNewUser(userId, name, email) {
        try {
            const response = await fetch('/walker/api_register', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user_id: userId,
                    name: name,
                    email: email
                })
            });
            
            const result = await response.json();
            
            if (result.status === 'success') {
                loadUserData(userId);
            }
        } catch (error) {
            console.error('Error registering user:', error);
        }
    }
    
    # Handle concept selection
    function handleConceptSelect(conceptName) {
        setSelectedConcept(conceptName);
        setCurrentView('lesson');
    }
    
    # Handle quiz start
    function handleStartQuiz(conceptName) {
        setSelectedConcept(conceptName);
        setCurrentView('quiz');
    }
    
    # Handle navigation
    function handleNavigation(view) {
        setCurrentView(view);
        if (view === 'dashboard') {
            setSelectedConcept(null);
        }
    }
    
    # Refresh progress data
    async function refreshProgress() {
        if (currentUser) {
            await loadUserData(currentUser.userId);
        }
    }
    
    # Render loading state
    if (loading) {
        return (
            <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center">
                <div className="text-center">
                    <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-indigo-600 mx-auto mb-4"></div>
                    <p className="text-gray-600 text-lg">Loading your learning journey...</p>
                </div>
            </div>
        );
    }
    
    # Main render
    return (
        <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
            {/* Navigation Bar */}
            <nav className="bg-white shadow-lg">
                <div className="container mx-auto px-4">
                    <div className="flex justify-between items-center py-4">
                        <div className="flex items-center space-x-4">
                            <h1 className="text-2xl font-bold text-indigo-600">
                                🎓 Jaseci Learning
                            </h1>
                        </div>
                        <div className="flex items-center space-x-4">
                            <button
                                onClick={() => handleNavigation('dashboard')}
                                className={`px-4 py-2 rounded-lg transition ${
                                    currentView === 'dashboard'
                                        ? 'bg-indigo-600 text-white'
                                        : 'text-gray-600 hover:bg-gray-100'
                                }`}
                            >
                                Dashboard
                            </button>
                            <button
                                onClick={() => handleNavigation('skillmap')}
                                className={`px-4 py-2 rounded-lg transition ${
                                    currentView === 'skillmap'
                                        ? 'bg-indigo-600 text-white'
                                        : 'text-gray-600 hover:bg-gray-100'
                                }`}
                            >
                                Skill Map
                            </button>
                            <div className="text-gray-600">
                                <span className="font-semibold">{currentUser?.name}</span>
                                <span className="ml-2 text-sm">
                                    ({Math.round(currentUser?.totalScore || 0)}% complete)
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </nav>
            
            <main className="container mx-auto px-4 py-8">
                {/* Dashboard View */}
                {currentView === 'dashboard' && (
                    <Dashboard
                        user={currentUser}
                        progress={userProgress}
                        onConceptSelect={handleConceptSelect}
                        onStartQuiz={handleStartQuiz}
                        onRefresh={refreshProgress}
                    />
                )}
                
                {/* Lesson View */}
                {currentView === 'lesson' && selectedConcept && (
                    <LessonView
                        userId={currentUser.userId}
                        conceptName={selectedConcept}
                        onBack={() => handleNavigation('dashboard')}
                        onStartQuiz={() => handleStartQuiz(selectedConcept)}
                        onComplete={refreshProgress}
                    />
                )}
                
                {/* Quiz View */}
                {currentView === 'quiz' && selectedConcept && (
                    <QuizView
                        userId={currentUser.userId}
                        conceptName={selectedConcept}
                        onBack={() => handleNavigation('dashboard')}
                        onComplete={refreshProgress}
                    />
                )}
                
                {/* Skill Map View */}
                {currentView === 'skillmap' && (
                    <SkillMap
                        userId={currentUser.userId}
                        onConceptClick={handleConceptSelect}
                    />
                )}
            </main>
            
            {/* Footer */}
            <footer className="bg-white border-t border-gray-200 mt-12 py-6">
                <div className="container mx-auto px-4 text-center text-gray-600">
                    <p>Jaseci Interactive Learning Platform • Built with Jac & Jaseci</p>
                    <p className="text-sm mt-2">Empowering developers to master AI-powered graph programming</p>
                </div>
            </footer>
        </div>
    );
}

# Simplified Dashboard Component (inline for demo)
function Dashboard({ user, progress, onConceptSelect, onStartQuiz, onRefresh }) {
    const [filter, setFilter] = useState('all');
    
    function getFilteredProgress() {
        if (filter === 'all') return progress;
        return progress.filter(p => p.status === filter);
    }
    
    function getStatusColor(status) {
        const colors = {
            'locked': 'gray',
            'unlocked': 'blue',
            'in_progress': 'yellow',
            'mastered': 'green'
        };
        return colors[status] || 'gray';
    }
    
    return (
        <div className="space-y-8">
            {/* Header */}
            <div className="bg-white rounded-lg shadow-lg p-8">
                <div className="flex justify-between items-center mb-4">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900 mb-2">
                            Welcome back, {user.name}! 👋
                        </h1>
                        <p className="text-gray-600">
                            Continue your learning journey with Jaseci
                        </p>
                    </div>
                    <div className="text-right">
                        <div className="text-4xl font-bold text-indigo-600">
                            {Math.round(user.totalScore)}%
                        </div>
                        <div className="text-sm text-gray-500">Overall Progress</div>
                    </div>
                </div>
                
                {/* Progress Bar */}
                <div className="mt-6">
                    <div className="flex justify-between text-sm text-gray-600 mb-2">
                        <span>Keep learning!</span>
                        <span>
                            {progress.filter(p => p.status === 'mastered').length} / {progress.length} mastered
                        </span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-3">
                        <div 
                            className="bg-gradient-to-r from-indigo-500 to-purple-600 h-3 rounded-full transition-all duration-500"
                            style={{ width: `${user.totalScore}%` }}
                        ></div>
                    </div>
                </div>
                
                <div className="mt-6 flex gap-4">
                    <button
                        onClick={onRefresh}
                        className="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                    >
                        🔄 Refresh Progress
                    </button>
                </div>
            </div>
            
            {/* Filter Tabs */}
            <div className="bg-white rounded-lg shadow p-4">
                <div className="flex gap-2">
                    {['all', 'unlocked', 'in_progress', 'mastered'].map(f => (
                        <button
                            key={f}
                            onClick={() => setFilter(f)}
                            className={`px-4 py-2 rounded-lg font-medium transition ${
                                filter === f
                                    ? 'bg-indigo-600 text-white'
                                    : 'text-gray-600 hover:bg-gray-100'
                            }`}
                        >
                            {f.toUpperCase().replace('_', ' ')}
                        </button>
                    ))}
                </div>
            </div>
            
            {/* Concepts Grid */}
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                {getFilteredProgress().map((concept, index) => (
                    <div 
                        key={index}
                        className={`bg-white rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition ${
                            concept.status === 'locked' ? 'opacity-60' : 'cursor-pointer'
                        }`}
                        onClick={() => concept.status !== 'locked' && onConceptSelect(concept.concept_name)}
                    >
                        {/* Header */}
                        <div className={`bg-${getStatusColor(concept.status)}-500 p-4`}>
                            <h3 className="text-white font-bold text-lg mb-1">
                                {concept.concept_name}
                            </h3>
                            <div className="text-white/90 text-sm">
                                {concept.status === 'locked' ? '🔒 Locked' :
                                 concept.status === 'unlocked' ? '🆕 New' :
                                 concept.status === 'in_progress' ? '📚 In Progress' :
                                 '✅ Mastered'}
                            </div>
                        </div>
                        
                        {/* Body */}
                        <div className="p-4">
                            <p className="text-gray-600 text-sm mb-4">
                                {concept.description}
                            </p>
                            
                            {/* Mastery Progress */}
                            <div className="mb-4">
                                <div className="flex justify-between text-sm text-gray-600 mb-1">
                                    <span>Mastery</span>
                                    <span>{Math.round(concept.mastery_score * 100)}%</span>
                                </div>
                                <div className="w-full bg-gray-200 rounded-full h-2">
                                    <div 
                                        className={`bg-${getStatusColor(concept.status)}-500 h-2 rounded-full`}
                                        style={{ width: `${concept.mastery_score * 100}%` }}
                                    ></div>
                                </div>
                            </div>
                            
                            {/* Actions */}
                            {concept.status !== 'locked' && (
                                <div className="flex gap-2">
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            onConceptSelect(concept.concept_name);
                                        }}
                                        className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition text-sm"
                                    >
                                        📖 Learn
                                    </button>
                                    {concept.status !== 'unlocked' && (
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                onStartQuiz(concept.concept_name);
                                            }}
                                            className="flex-1 px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 transition text-sm"
                                        >
                                            📝 Quiz
                                        </button>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

# Placeholder components (you'll need to implement these separately)
function LessonView({ userId, conceptName, onBack, onStartQuiz, onComplete }) {
    return (
        <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-4">Lesson: {conceptName}</h2>
            <p className="text-gray-600 mb-4">Lesson content will be loaded here...</p>
            <div className="flex gap-4">
                <button onClick={onBack} className="px-6 py-2 bg-gray-200 rounded-lg">Back</button>
                <button onClick={onStartQuiz} className="px-6 py-2 bg-indigo-600 text-white rounded-lg">
                    Take Quiz
                </button>
            </div>
        </div>
    );
}

function QuizView({ userId, conceptName, onBack, onComplete }) {
    return (
        <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-4">Quiz: {conceptName}</h2>
            <p className="text-gray-600 mb-4">Quiz interface will be loaded here...</p>
            <button onClick={onBack} className="px-6 py-2 bg-gray-200 rounded-lg">Back</button>
        </div>
    );
}

function SkillMap({ userId, onConceptClick }) {
    return (
        <div className="bg-white rounded-lg shadow-lg p-8">
            <h2 className="text-2xl font-bold mb-4">🗺️ Your Learning Journey</h2>
            <p className="text-gray-600 mb-4">Skill map visualization will be rendered here...</p>
            <canvas className="w-full border-2 border-gray-200 rounded-lg" height="500"></canvas>
        </div>
    );
}

export default App;