import { useState, useEffect, useRef } from 'react';
import { Spawn } from 'jac-client';

component SkillMap(props) {
    state skillData = null;
    state loading = true;
    state selectedConcept = null;
    state hoveredConcept = null;
    
    const canvasRef = useRef(null);
    
    # Load skill map data
    effect(() => {
        loadSkillMap();
    }, []);
    
    # Render graph when data changes
    effect(() => {
        if (skillData && canvasRef.current) {
            renderGraph();
        }
    }, [skillData]);
    
    async can loadSkillMap() {
        state loading = true;
        try {
            const result = await Spawn('api_get_skillmap', {
                user_id: props.userId
            });
            
            if (result.concepts) {
                state skillData = result;
            }
        } catch (error) {
            console.error('Error loading skill map:', error);
        } finally {
            state loading = false;
        }
    }
    
    can renderGraph() {
        const canvas = canvasRef.current;
        if (!canvas) return;
        
        const ctx = canvas.getContext('2d');
        const width = canvas.width = canvas.offsetWidth;
        const height = canvas.height = 600;
        
        # Clear canvas
        ctx.clearRect(0, 0, width, height);
        
        # Calculate positions for nodes (simple grid layout)
        const nodes = skillData.concepts.map((concept, index) => {
            const row = Math.floor(index / 3);
            const col = index % 3;
            const x = (col + 1) * (width / 4);
            const y = (row + 1) * (height / (Math.ceil(skillData.concepts.length / 3) + 1));
            
            return {
                ...concept,
                x: x,
                y: y,
                radius: 50,
                progress: skillData.user_progress[concept.id]
            };
        });
        
        # Draw edges first (prerequisite connections)
        ctx.strokeStyle = '#CBD5E0';
        ctx.lineWidth = 2;
        
        skillData.edges.forEach(edge => {
            const fromNode = nodes.find(n => n.id === edge.from);
            const toNode = nodes.find(n => n.id === edge.to);
            
            if (fromNode && toNode) {
                ctx.beginPath();
                ctx.moveTo(fromNode.x, fromNode.y);
                ctx.lineTo(toNode.x, toNode.y);
                ctx.stroke();
                
                # Draw arrow
                const angle = Math.atan2(toNode.y - fromNode.y, toNode.x - fromNode.x);
                const arrowLength = 15;
                ctx.beginPath();
                ctx.moveTo(
                    toNode.x - toNode.radius * Math.cos(angle),
                    toNode.y - toNode.radius * Math.sin(angle)
                );
                ctx.lineTo(
                    toNode.x - toNode.radius * Math.cos(angle) - arrowLength * Math.cos(angle - Math.PI / 6),
                    toNode.y - toNode.radius * Math.sin(angle) - arrowLength * Math.sin(angle - Math.PI / 6)
                );
                ctx.lineTo(
                    toNode.x - toNode.radius * Math.cos(angle) - arrowLength * Math.cos(angle + Math.PI / 6),
                    toNode.y - toNode.radius * Math.sin(angle) - arrowLength * Math.sin(angle + Math.PI / 6)
                );
                ctx.closePath();
                ctx.fillStyle = '#CBD5E0';
                ctx.fill();
            }
        });
        
        # Draw nodes
        nodes.forEach(node => {
            const isHovered = hoveredConcept === node.id;
            const isSelected = selectedConcept === node.id;
            
            # Get color based on status
            let color = '#9CA3AF';  # Default gray for locked
            if (node.progress) {
                if (node.progress.status === 'mastered') {
                    color = '#10B981';  # Green
                } else if (node.progress.status === 'in_progress') {
                    color = '#F59E0B';  # Amber
                } else if (node.progress.status === 'unlocked') {
                    color = '#3B82F6';  # Blue
                }
            }
            
            # Draw outer ring for progress
            if (node.progress && node.progress.mastery > 0) {
                ctx.beginPath();
                ctx.arc(node.x, node.y, node.radius + 5, 0, 2 * Math.PI);
                ctx.strokeStyle = color;
                ctx.lineWidth = 6;
                ctx.stroke();
                
                # Draw mastery arc
                ctx.beginPath();
                ctx.arc(
                    node.x, 
                    node.y, 
                    node.radius + 5, 
                    -Math.PI / 2, 
                    -Math.PI / 2 + (2 * Math.PI * node.progress.mastery)
                );
                ctx.strokeStyle = color;
                ctx.lineWidth = 8;
                ctx.stroke();
            }
            
            # Draw main circle
            ctx.beginPath();
            ctx.arc(node.x, node.y, node.radius, 0, 2 * Math.PI);
            ctx.fillStyle = isHovered || isSelected ? color : '#FFFFFF';
            ctx.fill();
            ctx.strokeStyle = color;
            ctx.lineWidth = isHovered || isSelected ? 4 : 3;
            ctx.stroke();
            
            # Draw text
            ctx.fillStyle = isHovered || isSelected ? '#FFFFFF' : color;
            ctx.font = '14px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            
            # Wrap text
            const words = node.name.split(' ');
            const lines = [];
            let currentLine = words[0];
            
            for (let i = 1; i < words.length; i++) {
                const testLine = currentLine + ' ' + words[i];
                const metrics = ctx.measureText(testLine);
                if (metrics.width > node.radius * 1.5) {
                    lines.push(currentLine);
                    currentLine = words[i];
                } else {
                    currentLine = testLine;
                }
            }
            lines.push(currentLine);
            
            const lineHeight = 16;
            const startY = node.y - ((lines.length - 1) * lineHeight) / 2;
            lines.forEach((line, i) => {
                ctx.fillText(line, node.x, startY + i * lineHeight);
            });
            
            # Draw mastery percentage
            if (node.progress && node.progress.mastery > 0) {
                ctx.font = 'bold 12px sans-serif';
                ctx.fillText(
                    `${Math.round(node.progress.mastery * 100)}%`,
                    node.x,
                    node.y + node.radius - 15
                );
            }
        });
        
        # Store nodes for click detection
        canvas.nodes = nodes;
    }
    
    can handleCanvasClick(event) {
        const canvas = canvasRef.current;
        if (!canvas || !canvas.nodes) return;
        
        const rect = canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        # Check if click is on a node
        const clickedNode = canvas.nodes.find(node => {
            const distance = Math.sqrt(
                Math.pow(x - node.x, 2) + Math.pow(y - node.y, 2)
            );
            return distance <= node.radius;
        });
        
        if (clickedNode) {
            if (clickedNode.progress && clickedNode.progress.status !== 'locked') {
                props.onConceptClick(clickedNode.id);
            }
        }
    }
    
    can handleCanvasHover(event) {
        const canvas = canvasRef.current;
        if (!canvas || !canvas.nodes) return;
        
        const rect = canvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        
        # Check if hovering over a node
        const hoveredNode = canvas.nodes.find(node => {
            const distance = Math.sqrt(
                Math.pow(x - node.x, 2) + Math.pow(y - node.y, 2)
            );
            return distance <= node.radius;
        });
        
        if (hoveredNode) {
            state hoveredConcept = hoveredNode.id;
            canvas.style.cursor = hoveredNode.progress?.status !== 'locked' ? 'pointer' : 'default';
        } else {
            state hoveredConcept = null;
            canvas.style.cursor = 'default';
        }
    }
    
    if (loading) {
        return (
            <div class="flex justify-center items-center h-96">
                <div class="text-center">
                    <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto mb-4"></div>
                    <p class="text-gray-600">Loading skill map...</p>
                </div>
            </div>
        );
    }
    
    return (
        <div class="max-w-7xl mx-auto">
            <div class="bg-white rounded-lg shadow-lg p-8">
                <div class="mb-6">
                    <h1 class="text-3xl font-bold text-gray-900 mb-2">
                        🗺️ Your Learning Journey
                    </h1>
                    <p class="text-gray-600">
                        Visual representation of your progress through Jaseci concepts
                    </p>
                </div>
                
                {# Legend #}
                <div class="flex flex-wrap gap-4 mb-6 p-4 bg-gray-50 rounded-lg">
                    <div class="flex items-center">
                        <div class="w-4 h-4 rounded-full bg-gray-400 mr-2"></div>
                        <span class="text-sm text-gray-700">Locked</span>
                    </div>
                    <div class="flex items-center">
                        <div class="w-4 h-4 rounded-full bg-blue-500 mr-2"></div>
                        <span class="text-sm text-gray-700">Unlocked</span>
                    </div>
                    <div class="flex items-center">
                        <div class="w-4 h-4 rounded-full bg-amber-500 mr-2"></div>
                        <span class="text-sm text-gray-700">In Progress</span>
                    </div>
                    <div class="flex items-center">
                        <div class="w-4 h-4 rounded-full bg-green-500 mr-2"></div>
                        <span class="text-sm text-gray-700">Mastered</span>
                    </div>
                    <div class="flex items-center ml-auto">
                        <span class="text-sm text-gray-500 italic">
                            Click on a concept to view details
                        </span>
                    </div>
                </div>
                
                {# Canvas #}
                <div class="border-2 border-gray-200 rounded-lg overflow-hidden">
                    <canvas
                        ref={canvasRef}
                        onClick={handleCanvasClick}
                        onMouseMove={handleCanvasHover}
                        class="w-full"
                        style={{ height: '600px' }}
                    />
                </div>
                
                {# Concept Details Panel #}
                {hoveredConcept && (
                    <div class="mt-6 p-6 bg-indigo-50 border border-indigo-200 rounded-lg">
                        {skillData.concepts
                            .filter(c => c.id === hoveredConcept)
                            .map(concept => {
                                const progress = skillData.user_progress[concept.id];
                                return (
                                    <div key={concept.id}>
                                        <div class="flex items-start justify-between mb-2">
                                            <h3 class="text-xl font-bold text-gray-900">
                                                {concept.name}
                                            </h3>
                                            <span class={`px-3 py-1 rounded-full text-sm ${
                                                concept.difficulty === 'beginner' ? 'bg-green-100 text-green-800' :
                                                concept.difficulty === 'intermediate' ? 'bg-yellow-100 text-yellow-800' :
                                                'bg-red-100 text-red-800'
                                            }`}>
                                                {concept.difficulty}
                                            </span>
                                        </div>
                                        <p class="text-gray-700 mb-4">{concept.description}</p>
                                        {progress && (
                                            <div class="grid grid-cols-3 gap-4">
                                                <div>
                                                    <div class="text-sm text-gray-600">Status</div>
                                                    <div class="font-semibold capitalize">{progress.status.replace('_', ' ')}</div>
                                                </div>
                                                <div>
                                                    <div class="text-sm text-gray-600">Mastery</div>
                                                    <div class="font-semibold">{Math.round(progress.mastery * 100)}%</div>
                                                </div>
                                                <div>
                                                    <div class="text-sm text-gray-600">Attempts</div>
                                                    <div class="font-semibold">{progress.attempts}</div>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                    </div>
                )}
                
                {# Statistics Summary #}
                <div class="mt-6 grid grid-cols-4 gap-4">
                    <div class="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-4 text-center">
                        <div class="text-2xl font-bold text-blue-700">
                            {skillData.concepts.length}
                        </div>
                        <div class="text-sm text-blue-600">Total Concepts</div>
                    </div>
                    <div class="bg-gradient-to-br from-green-50 to-green-100 rounded-lg p-4 text-center">
                        <div class="text-2xl font-bold text-green-700">
                            {Object.values(skillData.user_progress).filter(p => p.status === 'mastered').length}
                        </div>
                        <div class="text-sm text-green-600">Mastered</div>
                    </div>
                    <div class="bg-gradient-to-br from-amber-50 to-amber-100 rounded-lg p-4 text-center">
                        <div class="text-2xl font-bold text-amber-700">
                            {Object.values(skillData.user_progress).filter(p => p.status === 'in_progress').length}
                        </div>
                        <div class="text-sm text-amber-600">In Progress</div>
                    </div>
                    <div class="bg-gradient-to-br from-purple-50 to-purple-100 rounded-lg p-4 text-center">
                        <div class="text-2xl font-bold text-purple-700">
                            {Object.values(skillData.user_progress).filter(p => p.status === 'unlocked').length}
                        </div>
                        <div class="text-sm text-purple-600">Available</div>
                    </div>
                </div>
            </div>
        </div>
    );
}

export default SkillMap;