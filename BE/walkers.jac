import:py from datetime import datetime;
import:py import uuid;

# Walker to initialize the learning platform
walker InitializePlatform {
    has concepts_data: list[dict];
    
    can init_graph with LearningPlatform entry {
        # Create concepts from provided data
        concept_nodes = {};
        
        for concept_data in self.concepts_data {
            concept = here ++> Concept(
                name=concept_data.get("name"),
                description=concept_data.get("description"),
                difficulty=concept_data.get("difficulty", "beginner"),
                content=concept_data.get("content", ""),
                code_examples=concept_data.get("code_examples", []),
                order=concept_data.get("order", 0)
            );
            concept_nodes[concept_data["name"]] = concept;
        }
        
        # Create prerequisite edges
        for concept_data in self.concepts_data {
            if "prerequisites" in concept_data {
                source_concept = concept_nodes[concept_data["name"]];
                for prereq_name in concept_data["prerequisites"] {
                    if prereq_name in concept_nodes {
                        prereq_concept = concept_nodes[prereq_name];
                        prereq_concept ++> source_concept :Prerequisite:;
                    }
                }
            }
        }
        
        report {"status": "success", "concepts_created": len(concept_nodes)};
    }
}

# Walker to register a new user
walker RegisterUser {
    has user_id: str;
    has name: str;
    has email: str;
    
    can create_user with LearningPlatform entry {
        # Check if user already exists
        existing_users = [-->User(user_id==self.user_id)];
        if len(existing_users) > 0 {
            report {
                "status": "error",
                "message": "User already exists"
            };
            disengage;
        }
        
        # Create user node
        user = here ++> User(
            user_id=self.user_id,
            name=self.name,
            email=self.email,
            created_at=str(datetime.now())
        );
        
        # Get all concepts
        all_concepts = [-->Concept];
        
        # Initialize progress for all concepts
        for concept in all_concepts {
            progress = user ++> Progress(
                status="locked" if concept.order > 0 else "unlocked",
                mastery_score=0.0,
                attempts=0,
                last_attempt="",
                time_spent=0
            ) :HasProgress: {started_at: str(datetime.now())};
            
            progress ++> concept;
        }
        
        report {
            "status": "success",
            "user_id": self.user_id,
            "message": "User registered successfully"
        };
    }
}

# Walker to get user's current progress
walker GetUserProgress {
    has user_id: str;
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can collect_progress with User entry {
        progress_data = [];
        
        # Get all progress nodes connected to this user
        all_progress = [-->Progress];
        
        for progress in all_progress {
            # Get the concept connected to this progress
            concepts = [progress-->Concept];
            if len(concepts) > 0 {
                concept = concepts[0];
                progress_data.append({
                    "concept_name": concept.name,
                    "description": concept.description,
                    "mastery_score": progress.mastery_score,
                    "status": progress.status,
                    "attempts": progress.attempts,
                    "difficulty": concept.difficulty,
                    "order": concept.order
                });
            }
        }
        
        # Sort by order
        progress_data.sort(key=lambda x: x["order"]);
        
        report {
            "user_id": self.user_id,
            "name": here.name,
            "total_score": here.total_score,
            "progress": progress_data
        };
    }
}

# Walker to fetch a specific lesson
walker GetLesson {
    has user_id: str;
    has concept_name: str;
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can get_lesson with User entry {
        # Find the progress for this concept
        all_progress = [-->Progress];
        
        for progress in all_progress {
            concepts = [progress-->Concept];
            if len(concepts) > 0 and concepts[0].name == self.concept_name {
                concept = concepts[0];
                
                # Check if unlocked
                if progress.status == "locked" {
                    report {
                        "status": "error",
                        "message": "Concept is locked. Complete prerequisites first."
                    };
                    disengage;
                }
                
                # Mark as in progress if not already
                if progress.status == "unlocked" {
                    progress.status = "in_progress";
                }
                
                # Get prerequisites
                prereqs = [];
                prereq_concepts = [<--Prerequisite<--];
                for prereq in prereq_concepts {
                    if isinstance(prereq, Concept) {
                        prereqs.append(prereq.name);
                    }
                }
                
                report {
                    "status": "success",
                    "concept": {
                        "name": concept.name,
                        "description": concept.description,
                        "content": concept.content,
                        "code_examples": concept.code_examples,
                        "difficulty": concept.difficulty,
                        "prerequisites": prereqs
                    },
                    "progress": {
                        "mastery_score": progress.mastery_score,
                        "attempts": progress.attempts,
                        "time_spent": progress.time_spent
                    }
                };
                disengage;
            }
        }
        
        report {"status": "error", "message": "Concept not found"};
    }
}

# Walker to update learning progress
walker UpdateProgress {
    has user_id: str;
    has concept_name: str;
    has mastery_delta: float;
    has time_spent: int = 0;
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can update_progress with User entry {
        all_progress = [-->Progress];
        
        for progress in all_progress {
            concepts = [progress-->Concept];
            if len(concepts) > 0 and concepts[0].name == self.concept_name {
                concept = concepts[0];
                
                # Update mastery score
                old_mastery = progress.mastery_score;
                progress.mastery_score = min(1.0, max(0.0, 
                    progress.mastery_score + self.mastery_delta));
                progress.attempts += 1;
                progress.time_spent += self.time_spent;
                progress.last_attempt = str(datetime.now());
                
                # Update status based on mastery
                if progress.mastery_score >= concept.mastery_threshold {
                    progress.status = "mastered";
                    
                    # Unlock next concepts
                    spawn here walker::unlock_next_concepts(
                        user=here,
                        mastered_concept=concept
                    );
                } elif progress.status == "unlocked" {
                    progress.status = "in_progress";
                }
                
                # Update user's total score
                here.total_score = spawn here walker::calculate_total_score(user=here);
                
                report {
                    "status": "success",
                    "mastery_score": progress.mastery_score,
                    "progress_status": progress.status,
                    "total_score": here.total_score
                };
                disengage;
            }
        }
        
        report {"status": "error", "message": "Progress not found"};
    }
}

# Helper walker to unlock next concepts
walker unlock_next_concepts {
    has user: User;
    has mastered_concept: Concept;
    
    can unlock with `root entry {
        # Find concepts that have mastered_concept as prerequisite
        next_concepts = [self.mastered_concept-->Prerequisite-->Concept];
        
        for next_concept in next_concepts {
            # Check if all prerequisites are mastered
            all_prereqs_met = True;
            prereq_concepts = [next_concept<--Prerequisite<--Concept];
            
            for prereq in prereq_concepts {
                # Find progress for this prereq
                prereq_mastered = False;
                user_progress = [self.user-->Progress];
                
                for progress in user_progress {
                    prog_concepts = [progress-->Concept];
                    if len(prog_concepts) > 0 and prog_concepts[0].name == prereq.name {
                        if progress.status == "mastered" {
                            prereq_mastered = True;
                        }
                    }
                }
                
                if not prereq_mastered {
                    all_prereqs_met = False;
                    break;
                }
            }
            
            # Unlock if all prerequisites met
            if all_prereqs_met {
                user_progress = [self.user-->Progress];
                for progress in user_progress {
                    prog_concepts = [progress-->Concept];
                    if len(prog_concepts) > 0 and prog_concepts[0].name == next_concept.name {
                        if progress.status == "locked" {
                            progress.status = "unlocked";
                        }
                    }
                }
            }
        }
    }
}

# Helper walker to calculate total score
walker calculate_total_score {
    has user: User;
    
    can calculate with `root entry {
        total = 0.0;
        count = 0;
        
        user_progress = [self.user-->Progress];
        for progress in user_progress {
            total += progress.mastery_score;
            count += 1;
        }
        
        report (total / count * 100) if count > 0 else 0.0;
    }
}

# Walker to get skill map data for visualization
walker GetSkillMap {
    has user_id: str;
    
    can find_user with LearningPlatform entry {
        users = [-->User(user_id==self.user_id)];
        if len(users) > 0 {
            visit users[0];
        } else {
            report {"status": "error", "message": "User not found"};
        }
    }
    
    can build_skill_map with User entry {
        concepts = [];
        edges = [];
        user_progress = {};
        
        # Collect all progress data
        all_progress = [-->Progress];
        
        for progress in all_progress {
            prog_concepts = [progress-->Concept];
            if len(prog_concepts) > 0 {
                concept = prog_concepts[0];
                
                concepts.append({
                    "id": concept.name,
                    "name": concept.name,
                    "description": concept.description,
                    "difficulty": concept.difficulty,
                    "order": concept.order
                });
                
                user_progress[concept.name] = {
                    "mastery": progress.mastery_score,
                    "status": progress.status,
                    "attempts": progress.attempts
                };
                
                # Collect prerequisite edges
                prereq_concepts = [concept<--Prerequisite<--Concept];
                for prereq in prereq_concepts {
                    edges.append({
                        "from": prereq.name,
                        "to": concept.name,
                        "type": "prerequisite"
                    });
                }
            }
        }
        
        report {
            "concepts": concepts,
            "edges": edges,
            "user_progress": user_progress
        };
    }
}