import:jac from models, *;
import:jac from walkers, *;
import:jac from llm_walkers, *;

# Global walker to initialize the learning platform with sample data
glob walker BootstrapPlatform {
    can setup with `root entry {
        # Check if platform already exists
        existing_platforms = [-->LearningPlatform];
        
        if len(existing_platforms) > 0 {
            print("Platform already initialized");
            report {"status": "already_initialized", "platform": existing_platforms[0]};
            disengage;
        }
        
        # Create the main platform node
        platform = here ++> LearningPlatform(
            platform_name="Jaseci Interactive Learning",
            version="1.0.0"
        );
        
        print("Creating platform node...");
        
        # Sample curriculum data
        concepts = [
            {
                "name": "Introduction to Jac",
                "description": "Learn the basics of Jac programming language",
                "difficulty": "beginner",
                "content": """# Introduction to Jac

Jac is a modern programming language designed for building AI-powered applications with Jaseci.

## Key Features:
- Data spatial programming
- Built-in AI integration with byLLM
- Graph-native architecture
- Clean, Python-like syntax

## Your First Jac Program:
```jac
walker hello {
    can greet with `root entry {
        print("Hello, Jaseci!");
    }
}
```

## Core Concepts:
1. **Nodes** - Data containers in the graph
2. **Edges** - Relationships between nodes
3. **Walkers** - Code that traverses the graph
4. **Abilities** - Functions within walkers

Start your journey by understanding these fundamental building blocks!""",
                "code_examples": [
                    "walker simple {\n    can run with `root entry {\n        print('Hello Jac!');\n    }\n}",
                    "node Person {\n    has name: str;\n    has age: int;\n}"
                ],
                "order": 0,
                "prerequisites": []
            },
            {
                "name": "Nodes and Edges",
                "description": "Understanding the graph data model",
                "difficulty": "beginner",
                "content": """# Nodes and Edges in Jac

Jac uses a graph-based data model where:
- **Nodes** represent entities (data objects)
- **Edges** represent relationships between nodes

## Defining Nodes:
```jac
node Person {
    has name: str;
    has age: int;
    has email: str;
}
```

## Defining Edges:
```jac
edge Knows {
    has since: str;
    has relationship_type: str;
}
```

## Creating Connections:
```jac
# Connect two nodes with an edge
person1 ++> person2 :Knows: {since: "2020", relationship_type: "friend"};
```

## Traversing the Graph:
```jac
# Get all connected nodes
friends = [-->:Knows:-->Person];

# Get nodes with specific edge type
colleagues = [-->:WorksWith:-->Person];
```

The graph structure makes it natural to represent real-world relationships!""",
                "code_examples": [
                    "node Book {\n    has title: str;\n    has author: str;\n    has year: int;\n}",
                    "edge WrittenBy {\n    has year: int;\n}\n\nauthor ++> book :WrittenBy: {year: 2024};"
                ],
                "order": 1,
                "prerequisites": ["Introduction to Jac"]
            },
            {
                "name": "Walkers Basics",
                "description": "Learn how to traverse graphs with walkers",
                "difficulty": "intermediate",
                "content": """# Walkers in Jac

Walkers are the primary way to traverse and interact with your graph data.

## Basic Walker Structure:
```jac
walker FindPerson {
    has target_name: str;
    
    can search with Person entry {
        if here.name == self.target_name {
            report here;
            disengage;
        }
        visit [-->];
    }
}
```

## Walker Features:
- **State Management**: Use `has` to store data
- **Graph Navigation**: Use `visit` to move to other nodes
- **Reporting**: Use `report` to return data
- **Control Flow**: Use `disengage` to stop execution

## Entry Points:
- `with Node entry` - Triggered when walker visits that node type
- `with `root entry` - Triggered at the root node

## Example - Counting Nodes:
```jac
walker CountNodes {
    has total: int = 0;
    
    can count with Person entry {
        self.total += 1;
        visit [-->];
    }
}
```

Walkers make graph traversal intuitive and powerful!""",
                "code_examples": [
                    "walker Traverse {\n    can move with `root entry {\n        visit [-->];\n    }\n}",
                    "walker Count {\n    has total: int = 0;\n    \n    can increment with Node entry {\n        self.total += 1;\n    }\n}"
                ],
                "order": 2,
                "prerequisites": ["Nodes and Edges"]
            },
            {
                "name": "Object Spatial Programming",
                "description": "Master the OSP paradigm",
                "difficulty": "intermediate",
                "content": """# Object Spatial Programming (OSP)

OSP combines object-oriented and graph-based programming paradigms.

## Key Concepts:

### 1. Objects as Nodes
Data lives in graph nodes, not in isolated objects:
```jac
node User {
    has username: str;
    has email: str;
    has joined_date: str;
}
```

### 2. Relationships as Edges
Connections between data are explicit:
```jac
edge Follows {
    has since: str;
}

user1 ++> user2 :Follows: {since: "2024-01-01"};
```

### 3. Code as Walkers
Logic traverses the spatial graph:
```jac
walker GetFollowers {
    can find_followers with User entry {
        followers = [<--:Follows<--User];
        report followers;
    }
}
```

### 4. Spatial Queries
Navigate using graph patterns:
```jac
# Find friends of friends
fof = [-->:Knows:-->User-->:Knows:-->User];

# Find all posts by followed users
posts = [-->:Follows:-->User-->:Posted:-->Post];
```

## Benefits:
- Natural representation of relationships
- Efficient graph queries
- Scalable data organization
- Clear separation of data and logic

OSP makes complex relationship patterns simple to express!""",
                "code_examples": [
                    "# Spatial query example\nfriends = [-->:Knows:-->Person];",
                    "# Multi-hop traversal\nfof = [-->:Knows:-->Person-->:Knows:-->Person];"
                ],
                "order": 3,
                "prerequisites": ["Walkers Basics"]
            },
            {
                "name": "byLLM Integration",
                "description": "Build AI-powered applications",
                "difficulty": "advanced",
                "content": """# byLLM - AI Integration in Jac

byLLM allows seamless integration of Large Language Models into Jac code.

## Basic Usage:
```jac
walker Chatbot {
    has message: str;
    
    can respond(input: str) -> str by llm(
        model="gpt-4",
        temperature=0.7
    );
}
```

## Advanced Features:

### 1. ReAct Reasoning
```jac
can analyze(data: dict) -> dict by llm(
    reason=True,
    method="ReAct"
);
```

### 2. Context Injection
```jac
can process(user_data: dict) -> str by llm(
    incl_info=(user_data, context)
);
```

### 3. Structured Outputs
```jac
can classify(text: str) -> dict by llm(
    output_format="json"
);
```

## Real-World Example - Content Moderator:
```jac
walker ContentModerator {
    has content: str;
    
    can moderate() -> dict by llm(
        model="gpt-4",
        temperature=0.3,
        reason=True
    );
    
    can check with Post entry {
        result = self.moderate();
        
        if result["safe"] {
            here.status = "approved";
        } else {
            here.status = "flagged";
            here.reason = result["reason"];
        }
    }
}
```

## Best Practices:
- Use appropriate temperature (0.0-1.0)
- Provide clear prompts
- Use reasoning for complex tasks
- Handle errors gracefully
- Monitor token usage

byLLM makes your Jac applications intelligent!""",
                "code_examples": [
                    "can analyze(text: str) -> dict by llm(\n    model='gpt-4',\n    temperature=0.7\n);",
                    "can classify(content: str) -> str by llm(\n    reason=True,\n    method='ReAct'\n);"
                ],
                "order": 4,
                "prerequisites": ["Object Spatial Programming"]
            }
        ];
        
        # Initialize platform with concepts using the walker
        spawn InitializePlatform(concepts_data=concepts) on platform;
        
        print("Platform bootstrapped successfully!");
        report {"status": "success", "platform": platform};
    }
}

# API Walker: Register new user
walker api_register {
    has user_id: str;
    has name: str;
    has email: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn RegisterUser(
                user_id=self.user_id,
                name=self.name,
                email=self.email
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Get user progress
walker api_get_progress {
    has user_id: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn GetUserProgress(user_id=self.user_id) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Get lesson content
walker api_get_lesson {
    has user_id: str;
    has concept_name: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn GetLesson(
                user_id=self.user_id,
                concept_name=self.concept_name
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Update progress
walker api_update_progress {
    has user_id: str;
    has concept_name: str;
    has mastery_delta: float;
    has time_spent: int = 0;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn UpdateProgress(
                user_id=self.user_id,
                concept_name=self.concept_name,
                mastery_delta=self.mastery_delta,
                time_spent=self.time_spent
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Generate quiz
walker api_generate_quiz {
    has user_id: str;
    has concept_name: str;
    has num_questions: int = 5;
    has difficulty: str = "beginner";
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn GenerateQuiz(
                user_id=self.user_id,
                concept_name=self.concept_name,
                num_questions=self.num_questions,
                difficulty=self.difficulty
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Evaluate answer
walker api_evaluate_answer {
    has user_id: str;
    has session_id: str;
    has question_id: str;
    has answer_text: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn EvaluateAnswer(
                user_id=self.user_id,
                session_id=self.session_id,
                question_id=self.question_id,
                answer_text=self.answer_text
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Complete quiz
walker api_complete_quiz {
    has user_id: str;
    has session_id: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn CompleteQuiz(
                user_id=self.user_id,
                session_id=self.session_id
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Get skill map
walker api_get_skillmap {
    has user_id: str;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn GetSkillMap(user_id=self.user_id) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# API Walker: Get recommendations
walker api_get_recommendations {
    has user_id: str;
    has max_recommendations: int = 3;
    
    can handle_request with `root entry {
        platforms = [-->LearningPlatform];
        if len(platforms) > 0 {
            result = spawn GetRecommendations(
                user_id=self.user_id,
                max_recommendations=self.max_recommendations
            ) on platforms[0];
            report result;
        } else {
            report {"status": "error", "message": "Platform not initialized"};
        }
    }
}

# Main entry point - Bootstrap on startup
with entry {
    spawn BootstrapPlatform() on root;
}    print("Hello from Python backend!")