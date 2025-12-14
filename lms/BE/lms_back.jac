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
                return;
            }
        }
        
        report {
            "success": False,
            "message": "Course not found"
        };
    }
}

walker test_lms {
    can run_tests with `root entry {
        print("=== Testing LMS Backend ===");
        
        # Add courses
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
        print("✓ Added: Data Science");
        
        # Add students
        s1 = Student(
            id="student1@example.com",
            name="Alice Johnson",
            email="student1@example.com"
        );
        here ++> s1;
        print("✓ Added: Alice Johnson");
        
        # Add lessons
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
        
        # Get all courses
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "id": course_node.id,
                "title": course_node.title,
                "instructor": course_node.instructor
            });
        }
        
        print(f"\n✓ Found {len(courses)} courses:");
        for course in courses {
            print(f"  - {course['title']} by {course['instructor']}");
        }
        
        report {
            "success": True,
            "total_courses": len(courses),
            "message": "LMS test completed successfully"
        };
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
    }
}

# ==================== CLI ENTRY POINT ====================

with entry:__main__ {
    root spawn test_lms();
}