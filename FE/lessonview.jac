import { useState, useEffect, useRef } from 'react';
import { Spawn } from 'jac-client';
import { Light as SyntaxHighlighter } from 'react-syntax-highlighter';
import { docco } from 'react-syntax-highlighter/dist/esm/styles/hljs';

component LessonView(props) {
    state lesson = null;
    state loading = true;
    state activeTab = 'content';  # content, examples, practice
    state codeInput = '';
    state codeOutput = '';
    state timeSpent = 0;
    state showCompleteModal = false;
    
    const timerRef = useRef(null);
    
    # Load lesson on mount
    effect(() => {
        loadLesson();
        startTimer();
        
        return () => {
            stopTimer();
        };
    }, []);
    
    can startTimer() {
        timerRef.current = setInterval(() => {
            state timeSpent = timeSpent + 1;
        }, 60000);  # Increment every minute
    }
    
    can stopTimer() {
        if (timerRef.current) {
            clearInterval(timerRef.current);
        }
    }
    
    async can loadLesson() {
        state loading = true;
        try {
            const result = await Spawn('api_get_lesson', {
                user_id: props.userId,
                concept_name: props.conceptName
            });
            
            if (result.status === 'success') {
                state lesson = result;
            } else {
                console.error('Error:', result.message);
            }
        } catch (error) {
            console.error('Error loading lesson:', error);
        } finally {
            state loading = false;
        }
    }
    
    async can handleComplete() {
        stopTimer();
        
        try {
            # Update progress
            await Spawn('api_update_progress', {
                user_id: props.userId,
                concept_name: props.conceptName,
                mastery_delta: 0.1,  # Small boost for completing lesson
                time_spent: timeSpent
            });
            
            state showCompleteModal = true;
        } catch (error) {
            console.error('Error updating progress:', error);
        }
    }
    
    can runCode() {
        try {
            # Simulate code execution (in real implementation, use safe sandbox)
            state codeOutput = "Code execution simulated. In production, this would run in a safe sandbox.";
        } catch (error) {
            state codeOutput = `Error: ${error.message}`;
        }
    }
    
    if (loading) {
        return (
            <div class="flex justify-center items-center h-64">
                <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
            </div>
        );
    }
    
    if (!lesson || lesson.status === 'error') {
        return (
            <div class="bg-red-50 border border-red-200 rounded-lg p-6">
                <h3 class="text-red-800 font-semibold mb-2">Error Loading Lesson</h3>
                <p class="text-red-600">{lesson?.message || 'Failed to load lesson'}</p>
                <button
                    onClick={props.onBack}
                    class="mt-4 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
                >
                    Go Back
                </button>
            </div>
        );
    }
    
    return (
        <div class="max-w-5xl mx-auto">
            {# Complete Modal #}
            {showCompleteModal && (
                <div class="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
                    <div class="bg-white rounded-lg p-8 max-w-md mx-4">
                        <div class="text-center">
                            <div class="text-6xl mb-4">🎉</div>
                            <h2 class="text-2xl font-bold text-gray-900 mb-2">
                                Lesson Complete!
                            </h2>
                            <p class="text-gray-600 mb-6">
                                Great job! You've completed "{lesson.concept.name}".
                                Time spent: {timeSpent} minutes
                            </p>
                            <div class="flex gap-4">
                                <button
                                    onClick={() => {
                                        state showCompleteModal = false;
                                        props.onStartQuiz();
                                    }}
                                    class="flex-1 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
                                >
                                    Take Quiz
                                </button>
                                <button
                                    onClick={() => {
                                        props.onComplete();
                                        props.onBack();
                                    }}
                                    class="flex-1 px-4 py-2 bg-gray-200 text-gray-700 rounded hover:bg-gray-300"
                                >
                                    Dashboard
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
            
            {# Header #}
            <div class="bg-white rounded-lg shadow-lg p-6 mb-6">
                <div class="flex items-center justify-between mb-4">
                    <button
                        onClick={props.onBack}
                        class="text-indigo-600 hover:text-indigo-700 font-medium"
                    >
                        ← Back to Dashboard
                    </button>
                    <div class="text-sm text-gray-500">
                        ⏱️ {timeSpent} min
                    </div>
                </div>
                
                <h1 class="text-3xl font-bold text-gray-900 mb-2">
                    {lesson.concept.name}
                </h1>
                <p class="text-gray-600 mb-4">
                    {lesson.concept.description}
                </p>
                
                {# Progress Info #}
                <div class="flex items-center gap-4 text-sm">
                    <span class={`px-3 py-1 rounded-full bg-${
                        lesson.concept.difficulty === 'beginner' ? 'green' :
                        lesson.concept.difficulty === 'intermediate' ? 'yellow' : 'red'
                    }-100 text-${
                        lesson.concept.difficulty === 'beginner' ? 'green' :
                        lesson.concept.difficulty === 'intermediate' ? 'yellow' : 'red'
                    }-800`}>
                        {lesson.concept.difficulty.toUpperCase()}
                    </span>
                    <span class="text-gray-600">
                        Mastery: {Math.round(lesson.progress.mastery_score * 100)}%
                    </span>
                    <span class="text-gray-600">
                        Attempts: {lesson.progress.attempts}
                    </span>
                </div>
                
                {# Prerequisites #}
                {lesson.concept.prerequisites.length > 0 && (
                    <div class="mt-4 p-3 bg-blue-50 rounded border border-blue-200">
                        <span class="text-sm font-medium text-blue-800">
                            Prerequisites: {lesson.concept.prerequisites.join(', ')}
                        </span>
                    </div>
                )}
            </div>
            
            {# Tabs #}
            <div class="bg-white rounded-lg shadow-lg overflow-hidden">
                <div class="flex border-b">
                    {['content', 'examples', 'practice'].map(tab => (
                        <button
                            key={tab}
                            onClick={() => { state activeTab = tab; }}
                            class={`flex-1 px-6 py-4 font-medium transition ${
                                activeTab === tab
                                    ? 'bg-indigo-600 text-white'
                                    : 'text-gray-600 hover:bg-gray-50'
                            }`}
                        >
                            {tab === 'content' ? '📖 Content' :
                             tab === 'examples' ? '💡 Examples' :
                             '⚡ Practice'}
                        </button>
                    ))}
                </div>
                
                <div class="p-6">
                    {# Content Tab #}
                    {activeTab === 'content' && (
                        <div class="prose max-w-none">
                            <div 
                                class="markdown-content"
                                dangerouslySetInnerHTML={{ __html: lesson.concept.content }}
                            />
                        </div>
                    )}
                    
                    {# Examples Tab #}
                    {activeTab === 'examples' && (
                        <div class="space-y-6">
                            <h3 class="text-xl font-bold mb-4">Code Examples</h3>
                            {lesson.concept.code_examples.map((example, index) => (
                                <div key={index} class="bg-gray-50 rounded-lg overflow-hidden">
                                    <div class="bg-gray-200 px-4 py-2 text-sm font-medium text-gray-700">
                                        Example {index + 1}
                                    </div>
                                    <SyntaxHighlighter 
                                        language="python" 
                                        style={docco}
                                        customStyle={{ margin: 0, padding: '1rem' }}
                                    >
                                        {example}
                                    </SyntaxHighlighter>
                                </div>
                            ))}
                            {lesson.concept.code_examples.length === 0 && (
                                <p class="text-gray-500 italic">No code examples available for this lesson.</p>
                            )}
                        </div>
                    )}
                    
                    {# Practice Tab #}
                    {activeTab === 'practice' && (
                        <div class="space-y-4">
                            <h3 class="text-xl font-bold mb-4">Practice Coding</h3>
                            <p class="text-gray-600 mb-4">
                                Try writing some code based on what you've learned!
                            </p>
                            
                            <div class="border border-gray-300 rounded-lg overflow-hidden">
                                <div class="bg-gray-100 px-4 py-2 text-sm font-medium text-gray-700">
                                    Code Editor
                                </div>
                                <textarea
                                    value={codeInput}
                                    onChange={(e) => { state codeInput = e.target.value; }}
                                    class="w-full p-4 font-mono text-sm border-0 focus:ring-0 min-h-[200px]"
                                    placeholder="Write your Jac code here..."
                                />
                            </div>
                            
                            <button
                                onClick={runCode}
                                class="px-6 py-2 bg-green-600 text-white rounded hover:bg-green-700 transition"
                            >
                                ▶️ Run Code
                            </button>
                            
                            {codeOutput && (
                                <div class="bg-gray-900 text-green-400 p-4 rounded-lg font-mono text-sm">
                                    <div class="text-gray-400 mb-2">Output:</div>
                                    <pre>{codeOutput}</pre>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
            
            {# Action Buttons #}
            <div class="mt-6 flex justify-between">
                <button
                    onClick={props.onBack}
                    class="px-6 py-3 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
                >
                    ← Back to Dashboard
                </button>
                <div class="flex gap-4">
                    <button
                        onClick={handleComplete}
                        class="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition"
                    >
                        ✓ Mark Complete
                    </button>
                    <button
                        onClick={props.onStartQuiz}
                        class="px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                    >
                        Take Quiz →
                    </button>
                </div>
            </div>
        </div>
    );
}

export default LessonView;