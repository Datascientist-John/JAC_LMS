import { useState, useEffect } from 'react';
import { Spawn } from 'jac-client';

component QuizView(props) {
    state quiz = null;
    state loading = true;
    state currentQuestionIndex = 0;
    state answers = {};
    state submittedAnswers = {};
    state isComplete = false;
    state results = null;
    state evaluating = false;
    
    # Load quiz on mount
    effect(() => {
        generateQuiz();
    }, []);
    
    async can generateQuiz() {
        state loading = true;
        try {
            const result = await Spawn('api_generate_quiz', {
                user_id: props.userId,
                concept_name: props.conceptName,
                num_questions: 5,
                difficulty: 'beginner'
            });
            
            if (result.status === 'success') {
                state quiz = result;
                # Initialize answers object
                const initialAnswers = {};
                result.questions.forEach(q => {
                    initialAnswers[q.question_id] = '';
                });
                state answers = initialAnswers;
            }
        } catch (error) {
            console.error('Error generating quiz:', error);
        } finally {
            state loading = false;
        }
    }
    
    async can submitAnswer(questionId: str) {
        if (!answers[questionId]) {
            alert('Please provide an answer');
            return;
        }
        
        state evaluating = true;
        try {
            const result = await Spawn('api_evaluate_answer', {
                user_id: props.userId,
                session_id: quiz.session_id,
                question_id: questionId,
                answer_text: answers[questionId]
            });
            
            if (result.status === 'success') {
                state submittedAnswers = {
                    ...submittedAnswers,
                    [questionId]: result
                };
                
                # Move to next question
                if (currentQuestionIndex < quiz.questions.length - 1) {
                    state currentQuestionIndex = currentQuestionIndex + 1;
                }
            }
        } catch (error) {
            console.error('Error submitting answer:', error);
        } finally {
            state evaluating = false;
        }
    }
    
    async can completeQuiz() {
        state loading = true;
        try {
            const result = await Spawn('api_complete_quiz', {
                user_id: props.userId,
                session_id: quiz.session_id
            });
            
            if (result.status === 'success') {
                state results = result;
                state isComplete = true;
            }
        } catch (error) {
            console.error('Error completing quiz:', error);
        } finally {
            state loading = false;
        }
    }
    
    can getCurrentQuestion() {
        return quiz.questions[currentQuestionIndex];
    }
    
    can isQuestionAnswered(questionId: str) {
        return submittedAnswers.hasOwnProperty(questionId);
    }
    
    can getAnsweredCount() {
        return Object.keys(submittedAnswers).length;
    }
    
    if (loading && !quiz) {
        return (
            <div class="flex flex-col justify-center items-center h-64">
                <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4"></div>
                <p class="text-gray-600">Generating personalized quiz...</p>
            </div>
        );
    }
    
    # Results View
    if (isComplete && results) {
        return (
            <div class="max-w-3xl mx-auto">
                <div class="bg-white rounded-lg shadow-lg p-8">
                    <div class="text-center mb-8">
                        <div class="text-6xl mb-4">
                            {results.percentage >= 80 ? '🎉' :
                             results.percentage >= 60 ? '👍' :
                             results.percentage >= 40 ? '📚' : '💪'}
                        </div>
                        <h1 class="text-3xl font-bold text-gray-900 mb-2">
                            Quiz Complete!
                        </h1>
                        <p class="text-gray-600">
                            {results.percentage >= 80 ? 'Excellent work!' :
                             results.percentage >= 60 ? 'Good job!' :
                             results.percentage >= 40 ? 'Keep practicing!' :
                             'Don\'t give up!'}
                        </p>
                    </div>
                    
                    {# Score Display #}
                    <div class="grid grid-cols-3 gap-4 mb-8">
                        <div class="bg-indigo-50 rounded-lg p-4 text-center">
                            <div class="text-3xl font-bold text-indigo-600">
                                {Math.round(results.percentage)}%
                            </div>
                            <div class="text-sm text-gray-600">Score</div>
                        </div>
                        <div class="bg-green-50 rounded-lg p-4 text-center">
                            <div class="text-3xl font-bold text-green-600">
                                {results.correct_answers}/{results.total_questions}
                            </div>
                            <div class="text-sm text-gray-600">Correct</div>
                        </div>
                        <div class="bg-purple-50 rounded-lg p-4 text-center">
                            <div class="text-3xl font-bold text-purple-600">
                                {Math.round(results.mastery_score * 100)}%
                            </div>
                            <div class="text-sm text-gray-600">Mastery</div>
                        </div>
                    </div>
                    
                    {# AI Feedback #}
                    <div class="bg-blue-50 border border-blue-200 rounded-lg p-6 mb-6">
                        <h3 class="font-semibold text-blue-900 mb-2">
                            💡 AI Tutor Feedback
                        </h3>
                        <p class="text-blue-800">{results.feedback}</p>
                    </div>
                    
                    {# Next Steps #}
                    <div class="bg-gradient-to-r from-purple-50 to-indigo-50 rounded-lg p-6 mb-6">
                        <h3 class="font-semibold text-gray-900 mb-3">
                            📋 Recommended Next Steps
                        </h3>
                        <ul class="space-y-2">
                            {results.next_steps.map((step, index) => (
                                <li key={index} class="flex items-start">
                                    <span class="text-indigo-600 mr-2">•</span>
                                    <span class="text-gray-700">{step}</span>
                                </li>
                            ))}
                        </ul>
                    </div>
                    
                    {# Mastery Progress #}
                    <div class="mb-6">
                        <div class="flex justify-between text-sm text-gray-600 mb-2">
                            <span>Mastery Progress</span>
                            <span class="text-green-600 font-medium">
                                +{Math.round(results.mastery_change * 100)}%
                            </span>
                        </div>
                        <div class="w-full bg-gray-200 rounded-full h-3">
                            <div 
                                class="bg-gradient-to-r from-indigo-500 to-purple-600 h-3 rounded-full transition-all duration-500"
                                style={{ width: `${results.mastery_score * 100}%` }}
                            ></div>
                        </div>
                    </div>
                    
                    {# Action Buttons #}
                    <div class="flex gap-4">
                        <button
                            onClick={() => {
                                props.onComplete();
                                props.onBack();
                            }}
                            class="flex-1 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                        >
                            Back to Dashboard
                        </button>
                        <button
                            onClick={() => window.location.reload()}
                            class="flex-1 px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
                        >
                            Retake Quiz
                        </button>
                    </div>
                </div>
            </div>
        );
    }
    
    # Quiz Interface
    const currentQuestion = getCurrentQuestion();
    const answeredCount = getAnsweredCount();
    const isCurrentAnswered = isQuestionAnswered(currentQuestion.question_id);
    
    return (
        <div class="max-w-4xl mx-auto">
            {# Header #}
            <div class="bg-white rounded-lg shadow-lg p-6 mb-6">
                <div class="flex items-center justify-between mb-4">
                    <button
                        onClick={props.onBack}
                        class="text-indigo-600 hover:text-indigo-700 font-medium"
                    >
                        ← Back
                    </button>
                    <div class="text-sm text-gray-500">
                        {answeredCount} / {quiz.total_questions} answered
                    </div>
                </div>
                
                <h1 class="text-2xl font-bold text-gray-900 mb-2">
                    Quiz: {props.conceptName}
                </h1>
                
                {# Progress Bar #}
                <div class="w-full bg-gray-200 rounded-full h-2">
                    <div 
                        class="bg-indigo-600 h-2 rounded-full transition-all"
                        style={{ width: `${(answeredCount / quiz.total_questions) * 100}%` }}
                    ></div>
                </div>
            </div>
            
            {# Question Card #}
            <div class="bg-white rounded-lg shadow-lg p-8 mb-6">
                <div class="flex items-start justify-between mb-6">
                    <div class="flex-1">
                        <div class="text-sm font-medium text-gray-500 mb-2">
                            Question {currentQuestionIndex + 1} of {quiz.total_questions}
                        </div>
                        <h2 class="text-xl font-semibold text-gray-900">
                            {currentQuestion.question_text}
                        </h2>
                    </div>
                    <div class="ml-4 px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-medium">
                        {currentQuestion.points} pts
                    </div>
                </div>
                
                {# Answer Input #}
                {!isCurrentAnswered ? (
                    <div class="space-y-4">
                        {currentQuestion.type === 'multiple_choice' && (
                            <div class="space-y-3">
                                {currentQuestion.options.map((option, index) => (
                                    <label
                                        key={index}
                                        class="flex items-center p-4 border-2 border-gray-200 rounded-lg cursor-pointer hover:border-indigo-500 transition"
                                    >
                                        <input
                                            type="radio"
                                            name="answer"
                                            value={option}
                                            checked={answers[currentQuestion.question_id] === option}
                                            onChange={() => {
                                                state answers = {
                                                    ...answers,
                                                    [currentQuestion.question_id]: option
                                                };
                                            }}
                                            class="mr-3"
                                        />
                                        <span class="text-gray-700">{option}</span>
                                    </label>
                                ))}
                            </div>
                        )}
                        
                        {currentQuestion.type === 'free_text' && (
                            <textarea
                                value={answers[currentQuestion.question_id]}
                                onChange={(e) => {
                                    state answers = {
                                        ...answers,
                                        [currentQuestion.question_id]: e.target.value
                                    };
                                }}
                                class="w-full p-4 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:ring-0"
                                rows="4"
                                placeholder="Type your answer here..."
                            />
                        )}
                        
                        {currentQuestion.type === 'code' && (
                            <textarea
                                value={answers[currentQuestion.question_id]}
                                onChange={(e) => {
                                    state answers = {
                                        ...answers,
                                        [currentQuestion.question_id]: e.target.value
                                    };
                                }}
                                class="w-full p-4 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:ring-0 font-mono"
                                rows="6"
                                placeholder="// Write your code here..."
                            />
                        )}
                        
                        <button
                            onClick={() => submitAnswer(currentQuestion.question_id)}
                            disabled={evaluating || !answers[currentQuestion.question_id]}
                            class="w-full px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition disabled:bg-gray-300 disabled:cursor-not-allowed"
                        >
                            {evaluating ? 'Evaluating...' : 'Submit Answer'}
                        </button>
                    </div>
                ) : (
                    # Feedback Display
                    <div class="space-y-4">
                        <div class={`p-4 rounded-lg ${
                            submittedAnswers[currentQuestion.question_id].is_correct
                                ? 'bg-green-50 border border-green-200'
                                : 'bg-red-50 border border-red-200'
                        }`}>
                            <div class="flex items-center mb-2">
                                <span class="text-2xl mr-2">
                                    {submittedAnswers[currentQuestion.question_id].is_correct ? '✅' : '❌'}
                                </span>
                                <span class="font-semibold">
                                    {submittedAnswers[currentQuestion.question_id].is_correct
                                        ? 'Correct!'
                                        : 'Incorrect'}
                                </span>
                                <span class="ml-auto text-sm font-medium">
                                    +{submittedAnswers[currentQuestion.question_id].points_earned} pts
                                </span>
                            </div>
                            <p class="text-gray-700">
                                {submittedAnswers[currentQuestion.question_id].feedback}
                            </p>
                            {!submittedAnswers[currentQuestion.question_id].is_correct && (
                                <div class="mt-2 pt-2 border-t border-gray-300">
                                    <span class="text-sm font-medium">Correct answer: </span>
                                    <span class="text-sm">{submittedAnswers[currentQuestion.question_id].correct_answer}</span>
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </div>
            
            {# Navigation #}
            <div class="flex justify-between">
                <button
                    onClick={() => { 
                        if (currentQuestionIndex > 0) {
                            state currentQuestionIndex = currentQuestionIndex - 1;
                        }
                    }}
                    disabled={currentQuestionIndex === 0}
                    class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    ← Previous
                </button>
                
                {answeredCount === quiz.total_questions ? (
                    <button
                        onClick={completeQuiz}
                        class="px-8 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                    >
                        Complete Quiz →
                    </button>
                ) : (
                    <button
                        onClick={() => { 
                            if (currentQuestionIndex < quiz.questions.length - 1) {
                                state currentQuestionIndex = currentQuestionIndex + 1;
                            }
                        }}
                        disabled={currentQuestionIndex === quiz.questions.length - 1}
                        class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        Next →
                    </button>
                )}
            </div>
        </div>
    );
}

export default QuizView;