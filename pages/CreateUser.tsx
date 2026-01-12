
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { UserPlus, ArrowLeft } from 'lucide-react';
import { UserRole } from '../types';
import { initializeApp, deleteApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, updateProfile } from 'firebase/auth';
import { doc, setDoc } from 'firebase/firestore';
import { db } from '../services/firebaseConfig';

const CreateUser = () => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    role: UserRole.CLIENT_USER,
    clientId: '',
    clientName: ''
  });

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Using a temporary app instance to create user without logging out the current admin
    const tempApp = initializeApp({
      apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
      authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
      projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
      storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
      messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
      appId: import.meta.env.VITE_FIREBASE_APP_ID
    }, 'tempApp');

    const tempAuth = getAuth(tempApp);

    try {
      // 1. Create Authentication User
      const userCred = await createUserWithEmailAndPassword(tempAuth, formData.email, formData.password);
      await updateProfile(userCred.user, { displayName: formData.name });
      const newUid = userCred.user.uid;

      // 2. Create Firestore Profile (using main app's db which has admin rights)
      // We use the main 'db' instance (authenticated as the current Support Agent) to write the user profile.
      // This allows us to securely set the 'role' field, which a self-registered user (tempAuth) might not be trusted to do
      // depending on strict security rules. Our rules allow isManufacturer() to write to any user doc.
      await setDoc(doc(db, 'users', newUid), {
        email: formData.email,
        name: formData.name,
        role: formData.role,
        clientId: formData.clientId || 'unknown',
        clientName: formData.clientName || 'Unknown Client'
      });

      alert('User created successfully!');
      navigate('/');
    } catch (err: any) {
      console.error(err);
      alert('Error creating user: ' + err.message);
    } finally {
      await deleteApp(tempApp);
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-4">
      <button onClick={() => navigate('/')} className="flex items-center text-gray-600 mb-6 hover:text-blue-600">
        <ArrowLeft className="w-5 h-5 mr-2" /> Back to Dashboard
      </button>
      <div className="bg-white shadow-xl rounded-2xl border border-gray-100 overflow-hidden">
        <div className="bg-emerald-600 p-8 text-white">
          <div className="flex items-center space-x-3 mb-2">
            <UserPlus className="w-8 h-8" />
            <h1 className="text-2xl font-bold">Create New User</h1>
          </div>
          <p className="text-emerald-100 opacity-90">
            Provision a new account for a client or staff member.
          </p>
        </div>

        <form onSubmit={handleCreateUser} className="p-8 space-y-6">
          <div className="grid grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-2">Full Name</label>
              <input
                type="text"
                required
                className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </div>
            <div>
              <label className="block text-sm font-bold text-gray-700 mb-2">Role</label>
              <select
                className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
                value={formData.role}
                onChange={(e) => setFormData({ ...formData, role: e.target.value as UserRole })}
              >
                <option value={UserRole.CLIENT_USER}>Client User</option>
                <option value={UserRole.SUPPORT_AGENT}>Support Agent</option>
                <option value={UserRole.SUPERVISOR}>Supervisor</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">Email Address</label>
            <input
              type="email"
              required
              className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            />
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">Temporary Password</label>
            <input
              type="password"
              required
              className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
              value={formData.password}
              onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            />
          </div>

          {formData.role === UserRole.CLIENT_USER && (
            <div className="p-4 bg-gray-50 rounded-xl border border-gray-200 space-y-4">
              <h3 className="font-bold text-gray-700 text-sm">Client Organization Details</h3>
              <div>
                <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Client ID (Internal Code)</label>
                <input
                  type="text"
                  required={formData.role === UserRole.CLIENT_USER}
                  placeholder="e.g. client_tesla"
                  className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
                  value={formData.clientId}
                  onChange={(e) => setFormData({ ...formData, clientId: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-500 uppercase mb-1">Display Name</label>
                <input
                  type="text"
                  required={formData.role === UserRole.CLIENT_USER}
                  placeholder="e.g. Tesla Motors"
                  className="w-full border-gray-300 rounded-lg focus:ring-emerald-500 focus:border-emerald-500 text-sm py-2.5 px-4"
                  value={formData.clientName}
                  onChange={(e) => setFormData({ ...formData, clientName: e.target.value })}
                />
              </div>
            </div>
          )}

          <div className="pt-4 flex items-center justify-end">
            <button
              type="submit"
              disabled={loading}
              className="bg-emerald-600 text-white px-8 py-2.5 rounded-lg text-sm font-bold hover:bg-emerald-700 shadow-lg shadow-emerald-200 disabled:opacity-50 flex items-center"
            >
              <UserPlus className="w-4 h-4 mr-2" />
              {loading ? 'Creating...' : 'Create Account'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateUser;
