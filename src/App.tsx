import { BrowserRouter as Router } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthForm } from './components/AuthForm';
import { useAuthStore } from './stores/auth';
import { useEffect } from 'react';
import { supabase } from './lib/supabase';

const queryClient = new QueryClient();

function App() {
  const { user, loading } = useAuthStore();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      useAuthStore.setState({ user: session?.user ?? null, loading: false });
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      useAuthStore.setState({ user: session?.user ?? null });
    });

    return () => subscription.unsubscribe();
  }, []);

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <QueryClientProvider client={queryClient}>
      <Router>
        <div className="min-h-screen bg-gray-50">
          {user ? (
            <h1 className="text-3xl font-bold text-center py-8">
              Welcome to Budgetra
            </h1>
          ) : (
            <AuthForm />
          )}
        </div>
      </Router>
    </QueryClientProvider>
  );
}

export default App;