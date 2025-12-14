node User {
    has id: str;
    has name: str;
    has email: str;
    has role: str;  # 'student', 'teacher', 'admin'
}

node Course {
    has id: str;
    has title: str;
    has description: str;
    has teacher_id: str;
}

node Lesson {
    has id: str;
    has title: str;
    has content: str;
    has order: int;
}

node Assignment {
    has id: str;
    has title: str;
    has description: str;
    has due_date: str;
}

# Root node for the LMS
node LMSRoot {
    has name: str = "Learning Management System";
}

# Walker to get all courses
walker GetCourses {
    can handle with LMSRoot entry {
        courses = [
            {"id": "1", "title": "Introduction to Python", "description": "Learn Python basics"},
            {"id": "2", "title": "Web Development", "description": "Build modern web apps"}
        ];
        report {"courses": courses};
    }
}

# Walker to get user info
walker GetUserInfo {
    has user_id: str;
    
    can handle with LMSRoot entry {
        # In real app, fetch from database
        user = {
            "id": here.user_id,
            "name": "John Doe",
            "email": "john@example.com",
            "role": "student"
        };
        report {"user": user};
    }
}

# Walker to enroll in course
walker EnrollCourse {
    has user_id: str;
    has course_id: str;
    
    can handle with LMSRoot entry {
        report {
            "success": True,
            "message": f"User {here.user_id} enrolled in course {here.course_id}"
        };
    }
}

# Entry point
with entry {
    root ++> LMSRoot();
}