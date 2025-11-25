import { useState, useEffect } from 'react';
import { Spawn } from 'jac-client';

component Dashboard(props) {
    state recommendations = [];
    state loadingRecs = false;
    state filter = 'all';  # all, unlocked, in_progress, mastered
    
    # Load recommendations on mount
    effect(() => {
        loadRecommendations();
    }, []);
    
    async can loadRecommendations() {
        state loadingRecs = true;
        try {
            const result = await Spawn('api_get_recommendations', {
                user_id: props.user.userId,
                max_recommendations: 3
            });
            
            if (result.status === 'success') {
                state recommendations = result.recommendations;
            }
        } catch (error) {
            console.error('Error loading recommendations:', error);
        } finally {
            state loadingRecs = false;
        }
    }
    
    # Filter progress data
    can getFilteredProgress() {
        if (filter === 'all') {
            return props.progress;
        }
        return props.progress.filter(p => p.status === filter);
    }
    
    # Get status color
    can getStatusColor(status: str) {
        const colors = {
            'locked': 'gray',
            'unlocked': 'blue',
            'in_progress': 'yellow',
            'mastered': 'green'
        };
        return colors[status] || 'gray';
    }
    
    # Get difficulty badge color
    can getDifficultyColor(difficulty: str) {
        const colors = {
            'beginner': 'green',
            'intermediate': 'yellow',
            'advanced': 'red'
        };
        return colors[difficulty] || 'gray';
    }
    
    return (
        <div class="space-y-8">
            {# Header Section #}
            <div class="bg-white rounded-lg shadow-lg p-8">
                <div class="flex justify-between items-center">
                    <div>
                        <h1 class="text-3xl font-bold text-gray-900 mb-2">
                            Welcome back, {props.user.name}! 👋
                        </h1>
                        <p class="text-gray-600">
                            Continue your learning journey with Jaseci
                        </p>
                    </div>
                    <div class="text-right">
                        <div class="text-4xl font-bold text-indigo-600">
                            {Math.round(props.user.totalScore)}%
                        </div>
                        <div class="text-sm text-gray-500">Overall Progress</div>
                    </div>
                </div>
                
                {# Progress Bar #}
                <div class="mt-6">
                    <div class="flex justify-between text-sm text-gray-600 mb-2">
                        <span>Keep learning!</span>
                        <span>{props.progress.filter(p => p.status === 'mastered').length} / {props.progress.length} concepts mastered</span>
                    </div>
                    <div class="w-full bg-gray-200 rounded-full h-3">
                        <div 
                            class="bg-gradient-to-r from-indigo-500 to-purple-600 h-3 rounded-full transition-all duration-500"
                            style={{ width: `${props.user.totalScore}%` }}
                        ></div>
                    </div>
                </div>
                
                {# Quick Actions #}
                <div class="mt-6 flex gap-4">
                    <button
                        onClick={() => props.onNavigate('skillmap')}
                        class="px-6 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition"
                    >
                        📊 View Skill Map
                    </button>
                    <button
                        onClick={props.onRefresh}
                        class="px-6 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition"
                    >
                        🔄 Refresh Progress
                    </button>
                </div>
            </div>
            
            {# Recommendations Section #}
            {!loadingRecs && recommendations.length > 0 && (
                <div class="bg-gradient-to-r from-purple-500 to-indigo-600 rounded-lg shadow-lg p-6 text-white">
                    <h2 class="text-2xl font-bold mb-4">🎯 Recommended for You</h2>
                    <div class="grid md:grid-cols-3 gap-4">
                        {recommendations.map((rec, index) => (
                            <div 
                                key={index}
                                class="bg-white/10 backdrop-blur rounded-lg p-4 cursor-pointer hover:bg-white/20 transition"
                                onClick={() => props.onConceptSelect(rec.concept_name)}
                            >
                                <h3 class="font-semibold mb-2">{rec.concept_name}</h3>
                                <p class="text-sm text-white/80 mb-2">{rec.reason}</p>
                                <div class="text-xs">
                                    Priority: {rec.priority} • ~{rec.estimated_time} min
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
            
            {# Filter Tabs #}
            <div class="bg-white rounded-lg shadow p-4">
                <div class="flex gap-2 border-b pb-2">
                    {['all', 'unlocked', 'in_progress', 'mastered'].map(f => (
                        <button
                            key={f}
                            onClick={() => { state filter = f; }}
                            class={`px-4 py-2 rounded-lg font-medium transition ${
                                filter === f
                                    ? 'bg-indigo-600 text-white'
                                    : 'text-gray-600 hover:bg-gray-100'
                            }`}
                        >
                            {f.replace('_', ' ').toUpperCase()}
                        </button>
                    ))}
                </div>
            </div>
            
            {# Concepts Grid #}
            <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
                {getFilteredProgress().map((concept, index) => (
                    <div 
                        key={index}
                        class={`bg-white rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition ${
                            concept.status === 'locked' ? 'opacity-60' : 'cursor-pointer'
                        }`}
                        onClick={() => concept.status !== 'locked' && props.onConceptSelect(concept.concept_name)}
                    >
                        {# Header #}
                        <div class={`bg-${getStatusColor(concept.status)}-500 p-4`}>
                            <div class="flex justify-between items-start mb-2">
                                <h3 class="text-white font-bold text-lg">
                                    {concept.concept_name}
                                </h3>
                                <span class={`px-2 py-1 text-xs rounded bg-${getDifficultyColor(concept.difficulty)}-600 text-white`}>
                                    {concept.difficulty}
                                </span>
                            </div>
                            <div class="text-white/90 text-sm">
                                {concept.status === 'locked' ? '🔒 Locked' :
                                 concept.status === 'unlocked' ? '🆕 New' :
                                 concept.status === 'in_progress' ? '📚 In Progress' :
                                 '✅ Mastered'}
                            </div>
                        </div>
                        
                        {# Body #}
                        <div class="p-4">
                            <p class="text-gray-600 text-sm mb-4">
                                {concept.description}
                            </p>
                            
                            {# Mastery Progress #}
                            <div class="mb-4">
                                <div class="flex justify-between text-sm text-gray-600 mb-1">
                                    <span>Mastery</span>
                                    <span>{Math.round(concept.mastery_score * 100)}%</span>
                                </div>
                                <div class="w-full bg-gray-200 rounded-full h-2">
                                    <div 
                                        class={`bg-${getStatusColor(concept.status)}-500 h-2 rounded-full`}
                                        style={{ width: `${concept.mastery_score * 100}%` }}
                                    ></div>
                                </div>
                            </div>
                            
                            {# Stats #}
                            <div class="flex justify-between text-xs text-gray-500 mb-4">
                                <span>Attempts: {concept.attempts}</span>
                            </div>
                            
                            {# Actions #}
                            {concept.status !== 'locked' && (
                                <div class="flex gap-2">
                                    <button
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            props.onConceptSelect(concept.concept_name);
                                        }}
                                        class="flex-1 px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 transition text-sm"
                                    >
                                        📖 Learn
                                    </button>
                                    {concept.status !== 'unlocked' && (
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                props.onStartQuiz(concept.concept_name);
                                            }}
                                            class="flex-1 px-4 py-2 bg-purple-600 text-white rounded hover:bg-purple-700 transition text-sm"
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
            
            {getFilteredProgress().length === 0 && (
                <div class="bg-white rounded-lg shadow p-12 text-center">
                    <div class="text-6xl mb-4">🎯</div>
                    <h3 class="text-xl font-semibold text-gray-700 mb-2">
                        No concepts found
                    </h3>
                    <p class="text-gray-500">
                        Try changing the filter or complete some lessons!
                    </p>
                </div>
            )}
        </div>
    );
}

export default Dashboard;