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
    has order: int;            # Non-default arguments first
    has course_id: str;
    has video_url: str = "";   # Default arguments last
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
        # Generate simple ID based on title
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
        # Use email as ID
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
    
    can enroll with `root entry {
        visit [-->(`?Student)];
    }
    
    can process with Student entry {
        if here.id == self.student_id {
            if self.course_id not in here.enrolled_courses {
                here.enrolled_courses.append(self.course_id);
                report {
                    "success": True,
                    "message": "Student enrolled successfully"
                };
            } else {
                report {
                    "success": False,
                    "message": "Student already enrolled"
                };
            }
        }
    }
}

walker create_lesson {
    has course_id: str;
    has title: str;
    has content: str;
    has video_url: str = "";
    has order: int;
    
    can create with `root entry {
        lesson_id = f"{self.course_id}_lesson_{self.order}";
        
        new_lesson = Lesson(
            id=lesson_id,
            title=self.title,
            content=self.content,
            video_url=self.video_url,
            order=self.order,
            course_id=self.course_id
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

walker test_lms {
    can run_tests with `root entry {
        print("=== Testing LMS Backend ===");
        
        # Add courses directly
        c1 = Course(id="1", title="Python Basics", description="Learn Python", instructor="Dr. Smith", duration="6 weeks", level="beginner");
        here ++> c1;
        print("Added: Python Basics");
        
        c2 = Course(id="2", title="Data Science", description="Data analysis", instructor="Prof. Johnson", duration="10 weeks", level="intermediate");
        here ++> c2;
        print("Added: Data Science");
        
        # Get courses directly (no spawn)
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "id": course_node.id,
                "title": course_node.title,
                "description": course_node.description,
                "instructor": course_node.instructor,
                "duration": course_node.duration,
                "level": course_node.level
            });
        }
        
        print(f"\nFound {len(courses)} courses:");
        for course in courses {
            print(f"  - {course['title']} by {course['instructor']}");
        }
        
        # Test HTML rendering
        html = "<div class='courses'>";
        for course in courses {
            html += f"<div class='course'>{course['title']}</div>";
        }
        html += "</div>";
        print(f"\nHTML Output:\n{html}");
        
        report {"success": True, "total_courses": len(courses), "html": html};
    }
}

walker render_course_list {
    can display with `root entry {
        # Get courses directly without spawn
        courses = [];
        for course_node in [-->(`?Course)] {
            courses.append({
                "title": course_node.title,
                "id": course_node.id,
                "instructor": course_node.instructor
            });
        }
        
        html = "<div class='courses'>";
        for course in courses {
            html += f"<div class='course'>{course['title']}</div>";
        }
        html += "</div>";
        
        report {"content": html};
    }
}