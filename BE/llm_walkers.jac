"""
byLLM-powered walkers for adaptive learning
File: llm_walkers.jac
"""

import:py from datetime import datetime;
import:py import uuid;
import:py import json;

# Walker to generate quiz questions using byLLM
walker GenerateQuiz {
    has user_id: str;
    has concept_name: str;
    has num_questions: int = 5;
    has difficulty: str = "beginner";
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can generate_questions with User entry {
        # Find the concept and progress
        all_progress = [-->Progress];
        
        for progress in all_progress {
            concepts = [progress-->Concept];
            if len(concepts) > 0 and concepts[0].name == self.concept_name {
                concept = concepts[0];
                
                # Generate questions using byLLM
                questions = spawn here walker::generate_questions_with_llm(
                    concept=concept,
                    mastery_score=progress.mastery_score,
                    num_questions=self.num_questions,
                    difficulty=self.difficulty
                );
                
                # Create quiz session
                session_id = str(uuid.uuid4());
                session = here ++> QuizSession(
                    session_id=session_id,
                    started_at=str(datetime.now()),
                    total_questions=len(questions),
                    score=0.0,
                    correct_answers=0
                );
                session ++> concept;
                
                # Create question nodes
                question_data = [];
                for q_data in questions {
                    question_node = session ++> Question(
                        question_text=q_data["question"],
                        question_type=q_data["type"],
                        options=q_data.get("options", []),
                        correct_answer=q_data["correct_answer"],
                        difficulty=q_data.get("difficulty", self.difficulty),
                        points=q_data.get("points", 10),
                        explanation=q_data.get("explanation", "")
                    ) :HasQuestion: {weight: 1.0};
                    
                    question_data.append({
                        "question_id": session_id + "_q" + str(len(question_data)),
                        "question_text": q_data["question"],
                        "type": q_data["type"],
                        "options": q_data.get("options", []),
                        "points": q_data.get("points", 10)
                    });
                }
                
                report {
                    "status": "success",
                    "session_id": session_id,
                    "concept_name": concept.name,
                    "questions": question_data,
                    "total_questions": len(questions)
                };
                disengage;
            }
        }
        
        report {"status": "error", "message": "Concept not found"};
    }
}

# Helper walker to generate questions with LLM
walker generate_questions_with_llm {
    has concept: Concept;
    has mastery_score: float;
    has num_questions: int;
    has difficulty: str;
    
    can generate with `root entry {
        # Build prompt for LLM
        prompt = f"""Generate {self.num_questions} quiz questions for the concept: {self.concept.name}

Concept Description: {self.concept.description}
Difficulty Level: {self.difficulty}
Student Mastery Score: {self.mastery_score * 100}%

Generate questions that are appropriate for the student's current mastery level.
If mastery is low (< 50%), focus on fundamental concepts.
If mastery is medium (50-80%), include some application questions.
If mastery is high (> 80%), include challenging scenario-based questions.

Return a JSON array with {self.num_questions} questions in this exact format:
[
  {{
    "question": "Question text here?",
    "type": "multiple_choice" or "free_text" or "code",
    "options": ["Option A", "Option B", "Option C", "Option D"] (for multiple_choice only),
    "correct_answer": "The correct answer",
    "difficulty": "beginner" or "intermediate" or "advanced",
    "points": 10,
    "explanation": "Why this is the correct answer"
  }}
]

IMPORTANT: Return ONLY the JSON array, no other text.""";

        # Call LLM (simplified - in real implementation, use proper byLLM decorator)
        # For now, return sample questions based on difficulty
        if self.difficulty == "beginner" {
            questions = [
                {
                    "question": f"What is the main purpose of {self.concept.name}?",
                    "type": "multiple_choice",
                    "options": [
                        "To define data structures",
                        "To traverse graphs",
                        "To execute code",
                        "All of the above"
                    ],
                    "correct_answer": "All of the above",
                    "difficulty": "beginner",
                    "points": 10,
                    "explanation": f"{self.concept.name} encompasses multiple concepts in Jac programming."
                },
                {
                    "question": f"How would you describe {self.concept.name} in simple terms?",
                    "type": "free_text",
                    "options": [],
                    "correct_answer": f"A fundamental concept that helps in {self.concept.description.lower()}",
                    "difficulty": "beginner",
                    "points": 10,
                    "explanation": "Good answers should capture the core purpose."
                },
                {
                    "question": f"True or False: {self.concept.name} is used in Jac programming?",
                    "type": "multiple_choice",
                    "options": ["True", "False"],
                    "correct_answer": "True",
                    "difficulty": "beginner",
                    "points": 10,
                    "explanation": f"{self.concept.name} is a core concept in Jac."
                }
            ];
        } else {
            questions = [
                {
                    "question": f"Write a code example demonstrating {self.concept.name}",
                    "type": "code",
                    "options": [],
                    "correct_answer": f"// Sample implementation of {self.concept.name}",
                    "difficulty": self.difficulty,
                    "points": 15,
                    "explanation": "Your code should demonstrate proper usage."
                },
                {
                    "question": f"What are the key benefits of using {self.concept.name}?",
                    "type": "free_text",
                    "options": [],
                    "correct_answer": "Benefits include improved code organization and efficiency",
                    "difficulty": self.difficulty,
                    "points": 10,
                    "explanation": "Consider practical applications and advantages."
                }
            ];
        }
        
        report questions[:self.num_questions];
    }
}

# Walker to evaluate quiz answers using byLLM
walker EvaluateAnswer {
    has user_id: str;
    has session_id: str;
    has question_id: str;
    has answer_text: str;
    
    can find_session with LearningPlatform entry {
        # Find user first
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can evaluate with User entry {
        # Find quiz session
        all_sessions = [-->QuizSession];
        
        for session in all_sessions {
            if session.session_id == self.session_id {
                # Find the specific question
                questions = [session-->Question];
                
                for question in questions {
                    q_id = self.session_id + "_q" + str(questions.index(question));
                    if q_id == self.question_id {
                        # Evaluate the answer
                        evaluation = spawn here walker::evaluate_with_llm(
                            question=question,
                            answer=self.answer_text
                        );
                        
                        # Create answer node
                        answer = session ++> Answer(
                            answer_text=self.answer_text,
                            is_correct=evaluation["is_correct"],
                            points_earned=evaluation["points"],
                            feedback=evaluation["feedback"],
                            submitted_at=str(datetime.now())
                        ) :HasAnswer: {question_id: self.question_id};
                        
                        # Update session score
                        session.score += evaluation["points"];
                        if evaluation["is_correct"] {
                            session.correct_answers += 1;
                        }
                        
                        report {
                            "status": "success",
                            "is_correct": evaluation["is_correct"],
                            "points_earned": evaluation["points"],
                            "feedback": evaluation["feedback"],
                            "correct_answer": question.correct_answer if not evaluation["is_correct"] else None
                        };
                        disengage;
                    }
                }
            }
        }
        
        report {"status": "error", "message": "Question not found"};
    }
}

# Helper walker to evaluate answers with LLM
walker evaluate_with_llm {
    has question: Question;
    has answer: str;
    
    can evaluate with `root entry {
        is_correct = False;
        points = 0;
        feedback = "";
        
        # For multiple choice, exact match
        if self.question.question_type == "multiple_choice" {
            if self.answer.strip().lower() == self.question.correct_answer.strip().lower() {
                is_correct = True;
                points = self.question.points;
                feedback = "Correct! " + self.question.explanation;
            } else {
                is_correct = False;
                points = 0;
                feedback = "Incorrect. " + self.question.explanation;
            }
        }
        # For free text and code, use semantic similarity (simplified)
        else {
            # In real implementation, use LLM for evaluation
            # For now, simple keyword matching
            answer_lower = self.answer.lower();
            correct_lower = self.question.correct_answer.lower();
            
            # Check for key terms
            key_terms = correct_lower.split();
            matches = sum(1 for term in key_terms if len(term) > 3 and term in answer_lower);
            
            if matches >= len(key_terms) * 0.6 {
                is_correct = True;
                points = self.question.points;
                feedback = "Good answer! " + self.question.explanation;
            } elif matches >= len(key_terms) * 0.3 {
                is_correct = False;
                points = self.question.points // 2;
                feedback = "Partially correct. " + self.question.explanation;
            } else {
                is_correct = False;
                points = 0;
                feedback = "Needs improvement. " + self.question.explanation;
            }
        }
        
        report {
            "is_correct": is_correct,
            "points": points,
            "feedback": feedback
        };
    }
}

# Walker to complete quiz and update progress
walker CompleteQuiz {
    has user_id: str;
    has session_id: str;
    
    can find_session with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can finalize_quiz with User entry {
        all_sessions = [-->QuizSession];
        
        for session in all_sessions {
            if session.session_id == self.session_id {
                # Mark as completed
                session.completed_at = str(datetime.now());
                
                # Calculate final score
                max_score = session.total_questions * 10;
                score_percentage = (session.score / max_score) if max_score > 0 else 0;
                
                # Find associated concept
                concepts = [session-->Concept];
                if len(concepts) > 0 {
                    concept = concepts[0];
                    
                    # Calculate mastery delta
                    mastery_delta = 0.0;
                    if score_percentage >= 0.8 {
                        mastery_delta = 0.2;
                    } elif score_percentage >= 0.6 {
                        mastery_delta = 0.1;
                    } elif score_percentage >= 0.4 {
                        mastery_delta = 0.05;
                    } else {
                        mastery_delta = -0.05;
                    }
                    
                    # Update progress
                    all_progress = [here-->Progress];
                    for progress in all_progress {
                        prog_concepts = [progress-->Concept];
                        if len(prog_concepts) > 0 and prog_concepts[0].name == concept.name {
                            old_mastery = progress.mastery_score;
                            progress.mastery_score = min(1.0, max(0.0,
                                progress.mastery_score + mastery_delta));
                            progress.attempts += 1;
                            progress.last_attempt = str(datetime.now());
                            
                            # Update status
                            if progress.mastery_score >= concept.mastery_threshold {
                                progress.status = "mastered";
                            }
                            
                            # Generate feedback
                            feedback = spawn here walker::generate_feedback(
                                concept=concept,
                                score_pct=score_percentage,
                                new_mastery=progress.mastery_score,
                                old_mastery=old_mastery
                            );
                            
                            report {
                                "status": "success",
                                "session_id": self.session_id,
                                "score": session.score,
                                "max_score": max_score,
                                "percentage": score_percentage * 100,
                                "correct_answers": session.correct_answers,
                                "total_questions": session.total_questions,
                                "mastery_score": progress.mastery_score,
                                "mastery_change": mastery_delta,
                                "feedback": feedback["feedback"],
                                "next_steps": feedback["next_steps"]
                            };
                            disengage;
                        }
                    }
                }
            }
        }
        
        report {"status": "error", "message": "Quiz session not found"};
    }
}

# Helper walker to generate feedback
walker generate_feedback {
    has concept: Concept;
    has score_pct: float;
    has new_mastery: float;
    has old_mastery: float;
    
    can generate with `root entry {
        feedback = "";
        next_steps = [];
        
        # Generate feedback based on performance
        if self.score_pct >= 0.8 {
            feedback = f"Excellent work on {self.concept.name}! You demonstrated strong understanding of the concepts.";
            next_steps = [
                "Try the next advanced topic",
                "Help other learners with this concept",
                "Build a project using what you've learned"
            ];
        } elif self.score_pct >= 0.6 {
            feedback = f"Good effort on {self.concept.name}. You're making solid progress.";
            next_steps = [
                "Review the lesson materials again",
                "Practice with more code examples",
                "Take another quiz to reinforce learning"
            ];
        } elif self.score_pct >= 0.4 {
            feedback = f"You're on the right track with {self.concept.name}, but there's room for improvement.";
            next_steps = [
                "Revisit the lesson and take notes",
                "Focus on the fundamentals",
                "Try the practice exercises",
                "Don't hesitate to retake the quiz"
            ];
        } else {
            feedback = f"It seems {self.concept.name} needs more attention. Don't worry - learning takes time!";
            next_steps = [
                "Start from the beginning of the lesson",
                "Take your time with each section",
                "Practice the basic examples",
                "Consider reviewing prerequisite topics"
            ];
        }
        
        # Add mastery progress note
        improvement = self.new_mastery - self.old_mastery;
        if improvement > 0 {
            feedback += f" Your mastery increased by {int(improvement * 100)}%!";
        }
        
        report {
            "feedback": feedback,
            "next_steps": next_steps
        };
    }
}

# Walker to get personalized recommendations
walker GetRecommendations {
    has user_id: str;
    has max_recommendations: int = 3;
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can generate_recommendations with User entry {
        # Collect all progress data
        recommendations = [];
        all_progress = [-->Progress];
        
        # Find concepts to recommend
        for progress in all_progress {
            concepts = [progress-->Concept];
            if len(concepts) > 0 {
                concept = concepts[0];
                
                # Recommend unlocked concepts not yet mastered
                if progress.status == "unlocked" {
                    recommendations.append({
                        "concept_name": concept.name,
                        "reason": "This concept is available and ready to learn",
                        "priority": 3,
                        "estimated_time": 15,
                        "confidence": 0.9
                    });
                }
                # Recommend in-progress concepts with low mastery
                elif progress.status == "in_progress" and progress.mastery_score < 0.6 {
                    recommendations.append({
                        "concept_name": concept.name,
                        "reason": "You've started this - let's finish strong!",
                        "priority": 2,
                        "estimated_time": 20,
                        "confidence": 0.85
                    });
                }
                # Recommend reviewing mastered but not perfect concepts
                elif progress.status == "mastered" and progress.mastery_score < 0.95 {
                    recommendations.append({
                        "concept_name": concept.name,
                        "reason": "Polish your skills to near-perfection",
                        "priority": 1,
                        "estimated_time": 10,
                        "confidence": 0.7
                    });
                }
            }
        }
        
        # Sort by priority (higher is better) and limit
        recommendations.sort(key=lambda x: (-x["priority"], -x["confidence"]));
        recommendations = recommendations[:self.max_recommendations];
        
        # Create recommendation edges
        for rec in recommendations {
            for progress in all_progress {
                concepts = [progress-->Concept];
                if len(concepts) > 0 and concepts[0].name == rec["concept_name"] {
                    here ++> concepts[0] :Recommended: {
                        reason: rec["reason"],
                        confidence: rec.get("confidence", 0.8)
                    };
                }
            }
        }
        
        report {
            "status": "success",
            "recommendations": recommendations
        };
    }
}