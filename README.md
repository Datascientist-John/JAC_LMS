Jaseci Interactive Learning Platform
A self-paced, AI-powered learning portal for Jac and Jaseci, featuring adaptive quizzes, personalized recommendations, and visual skill mapping.
 Features

Object-Spatial Programming (OSP): Graph-based data model for tracking user progress
AI-Powered Learning: byLLM agents generate personalized quizzes and provide adaptive feedback
Visual Skill Map: Interactive graph visualization of learning journey
Adaptive Content: AI analyzes progress and recommends next steps
Interactive Code Editor: Practice Jac coding directly in the browser
Real-time Progress Tracking: Monitor mastery levels across all concepts

 Project Structure
jaseci-learning-platform/
├── backend/
│   ├── models.jac              # Data models (nodes, edges, objects)
│   ├── walkers.jac             # Core walker logic
│   ├── llm_walkers.jac         # AI-powered walkers
│   └── server.jac              # Main server & API endpoints
├── client/
│   ├── App.jac                 # Main application component
│   ├── components/
│   │   ├── Dashboard.jac       # Progress dashboard
│   │   ├── LessonView.jac      # Interactive lesson viewer
│   │   ├── QuizView.jac        # AI-generated quizzes
│   │   ├── SkillMap.jac        # Visual skill map
│   │   └── Navbar.jac          # Navigation component
│   └── styles/
│       └── globals.css         # Tailwind CSS styles
└── README.md
🛠️ Setup Instructions
Prerequisites

Jaseci Framework (latest version)
Node.js (v16+) for Jac-Client
Python (3.10+)
OpenAI API Key (for byLLM features)

Backend Setup

Install Jaseci:

bashpip install jaseci

Set up environment variables:

bashexport OPENAI_API_KEY="your-api-key-here"

Initialize the server:

bashcd backend
jac run server.jac
This will:

Create the learning platform graph
Initialize sample concepts (Jac basics, Walkers, OSP, byLLM)
Set up prerequisite relationships
Start the API server

Frontend Setup

Install Jac-Client dependencies:

bashcd client
npm install jac-client react react-dom
npm install react-syntax-highlighter
npm install -D tailwindcss postcss autoprefixer

Configure Tailwind CSS (tailwind.config.js):

javascriptmodule.exports = {
  content: ['./src/**/*.{jac,js,jsx,ts,tsx}'],
  theme: {
    extend: {},
  },
  plugins: [],
}

Start the development server:

bashnpm run dev
The application will be available at http://localhost:3000
 Usage Guide
For Learners

Register/Login: First-time users are automatically registered
Dashboard: View all available concepts and your progress
Learn: Click on any unlocked concept to view the lesson
Practice: Use the built-in code editor to practice Jac
Quiz: Take AI-generated quizzes to test your knowledge
Track Progress: View your skill map to see mastery levels

For Instructors

Add New Concepts: Modify the BootstrapPlatform walker in server.jac
Adjust Difficulty: Set mastery thresholds in concept definitions
Customize Prerequisites: Define the learning path in the concepts array

 Key Components Explained
Data Models (models.jac)

Concept Node: Represents a learning topic
User Node: Stores learner information
Progress Node: Tracks mastery for each user-concept pair
Question Node: AI-generated quiz questions
QuizSession Node: Manages quiz attempts

Core Walkers (walkers.jac)

InitializePlatform: Sets up the learning graph
RegisterUser: Creates new user and initializes progress
GetUserProgress: Retrieves all progress data
GetLesson: Fetches lesson content
UpdateProgress: Updates mastery scores and unlocks concepts
GetSkillMap: Generates visualization data

AI Walkers (llm_walkers.jac)

GenerateQuiz: Uses byLLM to create personalized questions
EvaluateAnswer: AI evaluates free-text and code answers
CompleteQuiz: Finalizes quiz and updates mastery
GetRecommendations: Analyzes progress and suggests next topics

Frontend Components

Dashboard: Overview of progress with concept cards
LessonView: Interactive lesson with tabs for content, examples, and practice
QuizView: Step-by-step quiz interface with AI feedback
SkillMap: Canvas-based visualization of concept relationships

 byLLM Integration
The platform uses byLLM decorators to integrate AI capabilities:
jaccan generate_questions_with_llm(
    concept: Concept, 
    mastery_score: float
) -> list[dict] by llm(
    model="gpt-4o-mini",
    temperature=0.7,
    max_tokens=2000,
    method="ReAct",
    reason=True,
    incl_info=(concept, mastery_score)
);
AI Features:

Adaptive Question Generation: Questions match user's skill level
Free-text Evaluation: AI grades open-ended answers
Personalized Feedback: Context-aware explanations
Smart Recommendations: Analyzes learning patterns

 API Endpoints
EndpointMethodDescription/registerPOSTRegister new user/progress/{user_id}GETGet user progress/lesson/{user_id}/{concept}GETGet lesson content/progress/updatePOSTUpdate mastery score/quiz/generatePOSTGenerate new quiz/quiz/answerPOSTSubmit and evaluate answer/quiz/completePOSTComplete quiz session/skillmap/{user_id}GETGet skill map data/recommendations/{user_id}GETGet AI recommendations
 Customization
Add New Concepts
Edit server.jac and add to the concepts array:
jac{
    "name": "Advanced Walkers",
    "description": "Master complex walker patterns",
    "difficulty": "advanced",
    "content": "Your lesson content...",
    "code_examples": ["example1", "example2"],
    "order": 5,
    "prerequisites": ["Walkers Basics", "Object Spatial Programming"]
}
Modify AI Behavior
Adjust byLLM parameters in llm_walkers.jac:

temperature: Creativity (0.0-1.0)
max_tokens: Response length
model: Choose AI model
method: "ReAct" for reasoning

Customize UI
Modify Tailwind classes in component files:

Change colors in the class attributes
Adjust layouts and spacing
Add custom animations

 Security Considerations

Code Execution: The practice editor simulates code execution. In production, use a secure sandbox (e.g., Docker containers)
API Keys: Store OpenAI keys in environment variables, never in code
User Data: Implement proper authentication and authorization
Input Validation: Sanitize all user inputs before processing

 Future Enhancements

 User authentication (JWT, OAuth)
 Real code execution sandbox
 Collaborative learning features
 Achievement badges and gamification
 Video lessons integration
 Community forums
 Mobile app version
 Offline mode support
 Multiple language support
 Advanced analytics dashboard

 Troubleshooting
Common Issues
Q: byLLM not working

Ensure OpenAI API key is set correctly
Check API quota and billing
Verify model name is correct

Q: Canvas not rendering

Clear browser cache
Check console for errors
Ensure canvas dimensions are set

Q: Progress not updating

Check walker execution in Jaseci logs
Verify user_id is correct
Ensure graph connections are valid

 Resources

Jaseci Documentation
Jac Language Guide
byLLM Documentation
Jac-Client Documentation

Contributing
Contributions are welcome! Please:

Fork the repository
Create a feature branch
Make your changes
Submit a pull request

License
MIT License - feel free to use for educational purposes
 Credits
Built with  using Jaseci Framework and Jac language

Happy Learning! 