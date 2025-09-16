import { useEffect, useState } from 'react';
import { Session, User } from '@supabase/supabase-js';
import { supabase, isSupabaseConfigured } from '@/lib/supabase';
import { UserType } from '@/types/database';
import { Database } from '../lib/database.types';

export function useAuth() {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [userType, setUserType] = useState<UserType>('passenger');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setUserType('passenger');
      setLoading(false);
      return;
    }

    // Get initial session
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        // Get user type from user metadata
        const userTypeFromMeta = session.user.user_metadata?.user_type as UserType;
        const finalUserType = userTypeFromMeta || 'passenger';
        console.log('Setting user type:', finalUserType, 'from metadata:', userTypeFromMeta);
        setUserType(finalUserType);
      } else {
        setUserType('passenger');
      }
      
      setLoading(false);
    });

    // Listen for auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      
      if (session?.user) {
        // Get user type from user metadata
        const userTypeFromMeta = session.user.user_metadata?.user_type as UserType;
        const finalUserType = userTypeFromMeta || 'passenger';
        console.log('Auth state changed - setting user type:', finalUserType, 'from metadata:', userTypeFromMeta);
        setUserType(finalUserType);
      } else {
        setUserType('passenger');
      }
      
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string, userType?: UserType) => {
    if (!isSupabaseConfigured()) {
      throw new Error('Supabase is not configured. Please set up your Supabase credentials.');
    }

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    
    // Update user metadata with selected user type if provided
    if (data.user && userType) {
      console.log('Updating user type to:', userType);
      
      // Update user metadata
      const { error: updateError } = await supabase.auth.updateUser({
        data: {
          ...data.user.user_metadata,
          user_type: userType,
        }
      });
      
      if (updateError) {
        console.error('Error updating user type:', updateError);
      } else {
        setUserType(userType);
      }
    } else if (data.user) {
      // Use existing user type or default to passenger
      const existingUserType = data.user.user_metadata?.user_type as UserType;
      setUserType(existingUserType || 'passenger');
    }
    
    return { data, error };
  };

  const signUp = async (email: string, password: string, fullName: string, userType: UserType) => {
    if (!isSupabaseConfigured()) {
      throw new Error('Supabase is not configured. Please set up your Supabase credentials.');
    }

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          user_type: userType,
        },
      },
    });

    if (data.user && !error) {
      // User type is stored in user metadata, no need for separate profile table
      setUserType(userType);
    }

    return { data, error };
  };

  const signOut = async () => {
    console.log('[useAuth] Starting signOut process...');
    console.log('[useAuth] Current user:', user?.email);
    console.log('[useAuth] Supabase configured:', isSupabaseConfigured());
    
    try {
      // Clear Supabase session if configured
      if (isSupabaseConfigured()) {
        console.log('[useAuth] Attempting to sign out from Supabase...');
        const { error } = await supabase.auth.signOut();
        if (error) {
          console.error('[useAuth] Supabase signOut error:', error);
          // Continue with local cleanup even if Supabase signOut fails
        } else {
          console.log('[useAuth] Supabase session cleared successfully');
        }
      } else {
        console.log('[useAuth] Supabase not configured, skipping Supabase signOut');
      }
      
      // Force clear the session from AsyncStorage
      console.log('[useAuth] Clearing AsyncStorage...');
      const AsyncStorage = (await import('@react-native-async-storage/async-storage')).default;
      const keys = await AsyncStorage.getAllKeys();
      console.log('[useAuth] All AsyncStorage keys:', keys);
      const supabaseKeys = keys.filter(key => key.includes('supabase'));
      if (supabaseKeys.length > 0) {
        await AsyncStorage.multiRemove(supabaseKeys);
        console.log('[useAuth] Cleared Supabase keys from AsyncStorage:', supabaseKeys);
      } else {
        console.log('[useAuth] No Supabase keys found in AsyncStorage');
      }
      
      // Always clear local state
      console.log('[useAuth] Clearing local state...');
      setSession(null);
      setUser(null);
      setUserType(null);
      setLoading(false);
      console.log('[useAuth] Local auth state cleared - user is now:', user);
      
      return { error: null };
    } catch (error) {
      console.error('[useAuth] SignOut error caught:', error);
      console.error('[useAuth] Error details:', JSON.stringify(error, null, 2));
      // Even on error, clear local state
      setSession(null);
      setUser(null);
      setUserType(null);
      setLoading(false);
      return { error: error as Error };
    }
  };

  return {
    session,
    user,
    userType,
    loading,
    signIn,
    signUp,
    signOut,
  };
}