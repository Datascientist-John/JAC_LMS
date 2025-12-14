# Mark this code for client-side compilation
client {
    import { useState, useEffect } from "react";
    
    # React component in Jac
    obj App {
        can render -> JSX.Element {
            # State management
            let [message, setMessage] = useState("");
            let [loading, setLoading] = useState(true);
            
            # Fetch data from backend
            useEffect(() => {
                fetch("/api/message")
                    .then(res => res.json())
                    .then(data => {
                        setMessage(data.message);
                        setLoading(false);
                    });
            }, []);
            
            # JSX return
            return (
                <div className="app">
                    <h1>Jac Full-Stack Application</h1>
                    {loading ? (
                        <p>Loading...</p>
                    ) : (
                        <p>{message}</p>
                    )}
                </div>
            );
        }
    }
    
    # Export the component
    export default App;
}