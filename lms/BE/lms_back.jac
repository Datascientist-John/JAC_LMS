# ==================== NODES ====================

node Course {
    has id: str;
    has title: str;
    has description: str;
    has instructor: str;
    has duration: str;
    has level: str;
    has enrolled_count: int = 0;
}

node Student {
    has id: str;
    has name: str;
    has email: str;
    has enrolled_courses: list = [];
}

# ============= USER NODE FOR AUTHENTICATION =============
node User {
    has id: str;
    has email: str;
    has password_hash: str;
    has name: str;
    has created_at: str;
    has role: str = "student";
    has is_active: bool = True;
}

node Lesson {
    has id: str;
    has title: str;
    has content: str;
    has course_id: str;
    has order: int;
    has video_url: str = "";
}

node Assignment {
    has id: str;
    has title: str;
    has description: str;
    has due_date: str;
    has max_score: int;
    has course_id: str;
}

# ==================== WALKERS ====================

# ============= FIXED: USER REGISTRATION WALKER =============
walker register_user {
    has email: str;
    has password: str;
    has name: str;
    has role: str = "student";
    
    can register with `root entry {
        # Check if user already exists
        for user_node in [-->(`?User)] {
            if user_node.email == self.email {
                report {
                    "success": False,
                    "message": "User with this email already exists"
                };
                disengage;  # FIXED: Use disengage instead of return
            }
        }
        
        # Create user ID
        user_id = self.email;
        
        # In production, use proper password hashing (bcrypt, argon2, etc.)
        import hashlib;
        password_hash = hashlib.sha256(self.password.encode()).hexdigest();
        
        # Get current timestamp
        import time;
        created_at = str(time.time());
    
        # Create new user
        new_user = User(
            id=user_id,
            email=self.email,
            password_hash=password_hash,
            created_at=created_at,
            name=self.name,
            role=self.role,
            is_active=True
        );
        
        here ++> new_user;
        
        # Also create a Student node if role is student
        if self.role == "student" {
            new_student = Student(
                id=user_id,
                name=self.name,
                email=self.email
            );
            here ++> new_student;
        }
        
        report {
            "success": True,
            "user_id": user_id,
            "message": "User registered successfully",
            "user": {
                "id": user_id,
                "email": self.email,
                "name": self.name,
                "role": self.role
            }
        };
        
        disengage;  # FIXED: Stop walker execution
    }
}

# ============= FIXED: USER LOGIN WALKER =============
walker login_user {
    has email: str;
    has password: str;
    
    can authenticate with `root entry {
        # Hash the provided password
        import hashlib;
        password_hash = hashlib.sha256(self.password.encode()).hexdigest();
        
        # Find user
        for user_node in [-->(`?User)] {
            if user_node.email == self.email {
                # Check if account is active
                if not user_node.is_active {
                    report {
                        "success": False,
                        "message": "Account is deactivated"
                    };
                    disengage;  # FIXED
                }
                
                # Verify password
                if user_node.password_hash == password_hash {
                    report {
                        "success": True,
                        "message": "Login successful",
                        "user": {
                            "id": user_node.id,
                            "email": user_node.email,
                            "name": user_node.name,
                            "role": user_node.role
                        }
                    };
                    disengage;  # FIXED
                } else {
                    report {
                        "success": False,
                        "message": "Invalid password"
                    };
                    disengage;  # FIXED
                }
            }
        }
        
        report {
            "success": False,
            "message": "User not found"
        };
        
        disengage;  # FIXED
    }
}

# ============= FIXED: GET USER PROFILE WALKER =============
walker get_user_profile {
    has user_id: str;
    
    can fetch_profile with `root entry {
        for user_node in [-->(`?User)] {
            if user_node.id == self.user_id {
                # Get enrolled courses if student
                enrolled_courses = [];
                if user_node.role == "student" {
                    for student_node in [-->(`?Student)] {
                        if student_node.id == self.user_id {
                            enrolled_courses = student_node.enrolled_courses;
                            break;
                        }
                    }
                }
                
                report {
                    "success": True,
                    "user": {
                        "id": user_node.id,
                        "email": user_node.email,
                        "name": user_node.name,
                        "role": user_node.role,
                        "created_at": user_node.created_at,
                        "is_active": user_node.is_active,
                        "enrolled_courses": enrolled_courses
                    }
                };
                disengage;  # FIXED
            }
        }
        
        report {
            "success": False,
            "message": "User not found"
        };
        
        disengage;  # FIXED
    }
}

# ============= FIXED: UPDATE USER PASSWORD WALKER =============
walker update_password {
    has user_id: str;
    has old_password: str;
    has new_password: str;
    
    can change_password with `root entry {
        import hashlib;
        old_hash = hashlib.sha256(self.old_password.encode()).hexdigest();
        new_hash = hashlib.sha256(self.new_password.encode()).hexdigest();
        
        for user_node in [-->(`?User)] {
            if user_node.id == self.user_id {
                # Verify old password
                if user_node.password_hash == old_hash {
                    user_node.password_hash = new_hash;
                    report {
                        "success": True,
                        "message": "Password updated successfully"
                    };
                    disengage;  # FIXED
                } else {
                    report {
                        "success": False,
                        "message": "Invalid old password"
                    };
                    disengage;  # FIXED
                }
            }
        }
        
        report {
            "success": False,
            "message": "User not found"
        };
        
        disengage;  # FIXED
    }
}

walker get_courses {
    can fetch with `root entry {
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "id": course_node.id,
                "title": course_node.title,
                "description": course_node.description,
                "instructor": course_node.instructor,
                "duration": course_node.duration,
                "level": course_node.level,
                "enrolled_count": course_node.enrolled_count
            });
        }
        report courses;
        disengage;  # ADDED
    }
}

walker create_course {
    has title: str;
    has description: str;
    has instructor: str;
    has duration: str;
    has level: str;
    
    can create with `root entry {
        course_id = self.title.replace(" ", "_").lower();
        
        new_course = Course(
            id=course_id,
            title=self.title,
            description=self.description,
            instructor=self.instructor,
            duration=self.duration,
            level=self.level
        );
        
        here ++> new_course;
        
        report {
            "success": True,
            "course_id": course_id,
            "message": "Course created successfully"
        };
        
        disengage;  # ADDED
    }
}

walker create_student {
    has name: str;
    has email: str;
    
    can create with `root entry {
        student_id = self.email;
        
        new_student = Student(
            id=student_id,
            name=self.name,
            email=self.email
        );
        
        here ++> new_student;
        
        report {
            "success": True,
            "student_id": student_id,
            "message": "Student created successfully"
        };
        
        disengage;  # ADDED
    }
}

walker enroll_student {
    has student_id: str;
    has course_id: str;
    has found: bool = False;
    
    can enroll with `root entry {
        # Process students directly without visit
        for student_node in [-->(`?Student)] {
            if student_node.id == self.student_id {
                if self.course_id not in student_node.enrolled_courses {
                    student_node.enrolled_courses.append(self.course_id);
                    
                    # Update course enrollment count
                    for course_node in [-->(`?Course)] {
                        if course_node.id == self.course_id {
                            course_node.enrolled_count += 1;
                            break;
                        }
                    }
                    
                    report {
                        "success": True,
                        "message": "Student enrolled successfully"
                    };
                    self.found = True;
                } else {
                    report {
                        "success": False,
                        "message": "Student already enrolled"
                    };
                    self.found = True;
                }
                break;
            }
        }
        
        if not self.found {
            report {
                "success": False,
                "message": "Student not found"
            };
        }
        
        disengage;  # ADDED
    }
}

walker create_lesson {
    has course_id: str;
    has title: str;
    has content: str;
    has order: int;
    has video_url: str = "";
    
    can create with `root entry {
        lesson_id = f"{self.course_id}_lesson_{self.order}";
        
        new_lesson = Lesson(
            id=lesson_id,
            title=self.title,
            content=self.content,
            course_id=self.course_id,
            order=self.order,
            video_url=self.video_url
        );
        
        here ++> new_lesson;
        
        report {
            "success": True,
            "lesson_id": lesson_id,
            "message": "Lesson created successfully"
        };
        
        disengage;  # ADDED
    }
}

walker create_assignment {
    has course_id: str;
    has title: str;
    has description: str;
    has due_date: str;
    has max_score: int;
    
    can create with `root entry {
        assignment_id = f"{self.course_id}_{self.title.replace(' ', '_').lower()}";
        
        new_assignment = Assignment(
            id=assignment_id,
            title=self.title,
            description=self.description,
            due_date=self.due_date,
            max_score=self.max_score,
            course_id=self.course_id
        );
        
        here ++> new_assignment;
        
        report {
            "success": True,
            "assignment_id": assignment_id,
            "message": "Assignment created successfully"
        };
        
        disengage;  # ADDED
    }
}

walker get_students {
    can fetch with `root entry {
        students = [];
        for student_node in [-->(`?Student)] {
            students.append({
                "id": student_node.id,
                "name": student_node.name,
                "email": student_node.email,
                "enrolled_courses": student_node.enrolled_courses
            });
        }
        report students;
        disengage;  # ADDED
    }
}

walker get_course_details {
    has course_id: str;
    
    can fetch with `root entry {
        for course_node in [-->(`?Course)] {
            if course_node.id == self.course_id {
                # Get lessons for this course
                lessons = [];
                for lesson_node in [-->(`?Lesson)] {
                    if lesson_node.course_id == self.course_id {
                        lessons.append({
                            "id": lesson_node.id,
                            "title": lesson_node.title,
                            "content": lesson_node.content,
                            "order": lesson_node.order,
                            "video_url": lesson_node.video_url
                        });
                    }
                }
                
                # Get assignments for this course
                assignments = [];
                for assignment_node in [-->(`?Assignment)] {
                    if assignment_node.course_id == self.course_id {
                        assignments.append({
                            "id": assignment_node.id,
                            "title": assignment_node.title,
                            "description": assignment_node.description,
                            "due_date": assignment_node.due_date,
                            "max_score": assignment_node.max_score
                        });
                    }
                }
                
                report {
                    "success": True,
                    "course": {
                        "id": course_node.id,
                        "title": course_node.title,
                        "description": course_node.description,
                        "instructor": course_node.instructor,
                        "duration": course_node.duration,
                        "level": course_node.level,
                        "enrolled_count": course_node.enrolled_count
                    },
                    "lessons": lessons,
                    "assignments": assignments
                };
                disengage;  # FIXED
            }
        }
        
        report {
            "success": False,
            "message": "Course not found"
        };
        
        disengage;  # FIXED
    }
}

walker test_lms {
    can run_tests with `root entry {
        print("=== Testing LMS Backend with Authentication ===\n");
        
        # Test user registration
        print(">>> Testing User Registration");
        u1 = User(
            created_at="2024-01-01T00:00:00",
            id="alice@example.com",
            email="alice@example.com",
            password_hash="hashed_password_123",
            name="Alice Johnson",
            role="student",
            is_active=True
        );
        here ++> u1;
        print("✓ Registered: Alice Johnson (Student)");
        
        u2 = User(
            created_at="2024-01-01T00:00:00",
            id="drjac@example.com",
            email="drjac@example.com",
            password_hash="hashed_password_456",
            name="Dr. Jac",
            role="instructor",
            is_active=True
        );
        here ++> u2;
        print("✓ Registered: Dr. Jac (Instructor)\n");
        
        # Add courses
        print(">>> Adding Courses");
        c1 = Course(
            id="python_basics",
            title="Python Basics",
            description="Learn Python from scratch",
            instructor="Dr. Jac",
            duration="6 weeks",
            level="beginner"
        );
        here ++> c1;
        print("✓ Added: Python Basics");
        
        c2 = Course(
            id="data_science",
            title="Data Science",
            description="Introduction to Data Science",
            instructor="Prof. Jayson",
            duration="10 weeks",
            level="intermediate"
        );
        here ++> c2;
        print("✓ Added: Data Science\n");
        
        # Add students
        print(">>> Adding Students");
        s1 = Student(
            id="alice@example.com",
            name="Alice Johnson",
            email="alice@example.com"
        );
        here ++> s1;
        print("✓ Added: Alice Johnson");
        
        # Add lessons
        print("\n>>> Adding Lessons");
        l1 = Lesson(
            id="python_basics_lesson_1",
            title="Introduction to Python",
            content="Learn the basics of Python programming",
            course_id="python_basics",
            order=1,
            video_url="https://example.com/video1"
        );
        here ++> l1;
        print("✓ Added: Lesson 1");
        
        # Get all users
        print("\n>>> Listing All Users");
        users = [];
        for user_node in [-->(`?User)] {
            users.append({
                "name": user_node.name,
                "email": user_node.email,
                "role": user_node.role
            });
        }
        for user in users {
            print(f"  - {user['name']} ({user['role']}) - {user['email']}");
        }
        
        # Get all courses
        print("\n>>> Listing All Courses");
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "id": course_node.id,
                "title": course_node.title,
                "instructor": course_node.instructor
            });
        }
        for course in courses {
            print(f"  - {course['title']} by {course['instructor']}");
        }
        
        print("\n✓ LMS test completed successfully!");
        
        report {
            "success": True,
            "total_users": len(users),
            "total_courses": len(courses),
            "message": "LMS test with authentication completed successfully"
        };
        
        disengage;  # ADDED
    }
}

walker view_courses {
    can display with `root entry {
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "id": course_node.id,
                "title": course_node.title,
                "description": course_node.description,
                "instructor": course_node.instructor,
                "duration": course_node.duration,
                "level": course_node.level,
                "enrolled_count": course_node.enrolled_count
            });
        }
        
        report courses;
        disengage;  # ADDED
    }
}
# ==================== ENROLL====================
walker enroll_course {
    has user_id: str;
    has course_id: str;

    can enroll_user with `root entry {
        # Find the user
        user_node = None;
        for user in [-->(`?User)] {
            if user.id == self.user_id {
                user_node = user;
                break;
            }
        }

        if not user_node {
            report {"success": False, "message": "User not found"};
            disengage;
        }

        # Find the course
        course_node = None;
        for course in [-->(`?Course)] {
            if course.id == self.course_id {
                course_node = course;
                break;
            }
        }

        if not course_node {
            report {"success": False, "message": "Course not found"};
            disengage;
        }

        # Find the student node to update enrolled_courses
        student_node = None;
        for student in [-->(`?Student)] {
            if student.id == self.user_id {
                student_node = student;
                break;
            }
        }

        if not student_node {
            report {"success": False, "message": "Student record not found"};
            disengage;
        }

        # Check if already enrolled
        if course_node.title in student_node.enrolled_courses {
            report {"success": False, "message": "Already enrolled in this course"};
            disengage;
        }

        # Enroll the user
        student_node.enrolled_courses.append(course_node.title);
        course_node.enrolled_count += 1;

        report {"success": True, "message": "Successfully enrolled!"};
        disengage;
    }
}
# ==================== CLI ENTRY POINT ====================

with entry:__main__ {
    root spawn test_lms();
}