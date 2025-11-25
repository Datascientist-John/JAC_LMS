import:py from datetime import datetime;

# Enum for difficulty levels
enum QuizDifficulty {
    BEGINNER = "beginner",
    INTERMEDIATE = "intermediate",
    ADVANCED = "advanced"
}

enum ConceptStatus {
    LOCKED = "locked",
    UNLOCKED = "unlocked",
    IN_PROGRESS = "in_progress",
    MASTERED = "mastered"
}

# Node representing a learning concept/topic
node Concept {
    has name: str;
    has description: str;
    has difficulty: str = QuizDifficulty.BEGINNER;
    has content: str;  # Lesson content
    has code_examples: list[str] = [];
    has mastery_threshold: float = 0.8;  # 80% to master
    has order: int = 0;  # Sequence in curriculum
}

# Node representing a user/learner
node User {
    has user_id: str;
    has name: str;
    has email: str;
    has created_at: str;
    has total_score: float = 0.0;
}

# Node tracking user's progress on a concept
node Progress {
    has mastery_score: float = 0.0;  # 0.0 to 1.0
    has status: str = ConceptStatus.LOCKED;
    has attempts: int = 0;
    has last_attempt: str = "";
    has time_spent: int = 0;  # in minutes
}

# Node representing a quiz question
node Question {
    has question_text: str;
    has question_type: str;  # "multiple_choice", "code", "free_text"
    has options: list[str] = [];  # For multiple choice
    has correct_answer: str;
    has difficulty: str = QuizDifficulty.BEGINNER;
    has points: int = 10;
    has explanation: str = "";
}

# Node representing a quiz session
node QuizSession {
    has session_id: str;
    has started_at: str;
    has completed_at: str = "";
    has score: float = 0.0;
    has total_questions: int = 0;
    has correct_answers: int = 0;
}

# Node representing a user's answer
node Answer {
    has answer_text: str;
    has is_correct: bool = False;
    has points_earned: float = 0.0;
    has feedback: str = "";
    has submitted_at: str;
}

# Edge representing prerequisite relationship
edge Prerequisite {
    has required_mastery: float = 0.7;  # How well prereq must be known
}

# Edge connecting user to their progress
edge HasProgress {
    has started_at: str;
}

# Edge connecting concept to questions
edge HasQuestion {
    has weight: float = 1.0;  # Question importance
}

# Edge connecting quiz session to answers
edge HasAnswer {
    has question_id: str;
}

# Edge for user recommendations
edge Recommended {
    has reason: str;
    has confidence: float = 0.0;
}

# Global root node for the learning graph
node LearningPlatform {
    has platform_name: str = "Jaseci Interactive Learning";
    has version: str = "1.0.0";
}

# Object to store quiz results
obj QuizResult {
    has session_id: str;
    has concept_name: str;
    has score: float;
    has mastery_update: float;
    has feedback: str;
    has next_steps: list[str];
}

# Object for learning recommendations
obj Recommendation {
    has concept_name: str;
    has reason: str;
    has priority: int;
    has estimated_time: int;
}

# Object for skill map visualization
obj SkillMapData {
    has concepts: list[dict];
    has edges: list[dict];
    has user_progress: dict;
}