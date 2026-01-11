
import React, { useState, useEffect, useRef } from 'react';
import { HashRouter, Routes, Route, Navigate, Link, useNavigate } from 'react-router-dom';
import { 
  LogOut, 
  LayoutDashboard, 
  PlusCircle, 
  User, 
  Bell, 
  Package2, 
  Menu, 
  X, 
  MessageSquare, 
  Activity, 
  Trash2,
  ExternalLink
} from 'lucide-react';
import LoginPage from './pages/LoginPage';
import Dashboard from './pages/Dashboard';
import TicketView from './pages/TicketView';
import NewTicket from './pages/NewTicket';
import CreateUser from './pages/CreateUser';
import { firebase } from './services/firebaseService';
import { User as UserType, UserRole, Notification } from './types';

// Fix: Interface for NotificationItem props to allow void or Promise<void> for onDelete
interface NotificationItemProps {
  notification: Notification;
  onClick: (id: string) => void;
  onDelete: (e: React.MouseEvent, id: string) => void | Promise<void>;
}

// Fix: Using React.FC to properly handle standard React props like 'key' in JSX and fix assignment issues
const NotificationItem: React.FC<NotificationItemProps> = ({ 
  notification, 
  onClick, 
  onDelete 
}) => (
  <div
    className={`w-full group text-left p-4 hover:bg-gray-50 transition-colors border-b border-gray-50 flex items-start space-x-3 cursor-pointer ${!notification.read ? 'bg-blue-50/30' : ''}`}
    onClick={() => onClick(notification.ticketId)}
  >
    <div className={`mt-0.5 p-1.5 rounded-lg flex-shrink-0 ${notification.type === 'COMMENT' ? 'bg-blue-100 text-blue-600' : 'bg-orange-100 text-orange-600'}`}>
      {notification.type === 'COMMENT' ? <MessageSquare className="w-3 h-3" /> : <Activity className="w-3 h-3" />}
    </div>
    <div className="flex-1 min-w-0">
      <p className="text-xs font-semibold text-gray-800 leading-tight mb-1 break-words">{notification.text}</p>
      <p className="text-[10px] text-gray-400 font-medium">{new Date(notification.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
    </div>
    <button 
      onClick={(e) => onDelete(e, notification.id)}
      className="opacity-0 group-hover:opacity-100 p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-md transition-all flex-shrink-0"
      title="Delete notification"
    >
      <Trash2 className="w-3.5 h-3.5" />
    </button>
  </div>
);

const Navigation = ({ user, onLogout }: { user: UserType, onLogout: () => void }) => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isNotifOpen, setIsNotifOpen] = useState(false);
  const [showAllModal, setShowAllModal] = useState(false);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const navigate = useNavigate();
  const notifRef = useRef<HTMLDivElement>(null);

  const toggleMenu = () => setIsMenuOpen(!isMenuOpen);
  
  const toggleNotif = async () => {
    if (!isNotifOpen) {
      const data = await firebase.getNotifications();
      setNotifications(data);
    } else {
      await firebase.markNotificationsRead();
      const data = await firebase.getNotifications();
      setNotifications(data);
    }
    setIsNotifOpen(!isNotifOpen);
  };

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (notifRef.current && !notifRef.current.contains(event.target as Node)) {
        if (isNotifOpen) {
          firebase.markNotificationsRead().then(() => {
            firebase.getNotifications().then(setNotifications);
          });
          setIsNotifOpen(false);
        }
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isNotifOpen]);

  useEffect(() => {
    const load = async () => {
      const data = await firebase.getNotifications();
      setNotifications(data);
    };
    load();
    const interval = setInterval(load, 5000);
    return () => clearInterval(interval);
  }, []);

  const unreadCount = notifications.filter(n => !n.read).length;

  const handleNotifClick = (ticketId: string) => {
    setIsNotifOpen(false);
    setShowAllModal(false);
    navigate(`/ticket/${ticketId}`);
  };

  const handleDeleteNotif = async (e: React.MouseEvent, id: string) => {
    e.stopPropagation();
    await firebase.deleteNotification(id);
    const data = await firebase.getNotifications();
    setNotifications(data);
  };

  return (
    <nav className="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between h-16">
          <div className="flex">
            <Link to="/" className="flex-shrink-0 flex items-center">
              <Package2 className="h-8 w-8 text-blue-600" />
              <span className="ml-2 text-xl font-bold text-gray-900">ForgeTrack</span>
            </Link>
            <div className="hidden md:ml-8 md:flex md:space-x-8">
              <Link to="/" className="border-transparent text-gray-500 hover:border-blue-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors">
                <LayoutDashboard className="w-4 h-4 mr-2" />
                Dashboard
              </Link>
              {user.role === UserRole.CLIENT_USER && (
                <Link to="/new-ticket" className="border-transparent text-gray-500 hover:border-blue-500 hover:text-gray-700 inline-flex items-center px-1 pt-1 border-b-2 text-sm font-medium transition-colors">
                  <PlusCircle className="w-4 h-4 mr-2" />
                  Raise Issue
                </Link>
              )}
            </div>
          </div>
          
          <div className="flex items-center space-x-2 md:space-x-4">
            <div className="relative" ref={notifRef}>
              <button 
                onClick={toggleNotif}
                className="p-2 text-gray-400 hover:text-gray-500 relative transition-colors focus:outline-none"
              >
                <Bell className="w-5 h-5" />
                {unreadCount > 0 && (
                  <span className="absolute top-1.5 right-1.5 flex h-4 w-4 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white ring-2 ring-white">
                    {unreadCount}
                  </span>
                )}
              </button>

              {/* Notification Dropdown */}
              {isNotifOpen && (
                <div className="absolute right-0 mt-2 w-80 bg-white rounded-xl shadow-2xl border border-gray-100 z-50 overflow-hidden">
                  <div className="p-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
                    <h3 className="text-xs font-bold text-gray-900 uppercase tracking-widest">Notifications</h3>
                    {unreadCount > 0 && <span className="text-[10px] font-bold text-blue-600">{unreadCount} new</span>}
                  </div>
                  <div className="max-h-80 overflow-y-auto">
                    {notifications.length > 0 ? (
                      notifications.slice(0, 5).map(n => (
                        <NotificationItem 
                          key={n.id} 
                          notification={n} 
                          onClick={handleNotifClick} 
                          onDelete={handleDeleteNotif} 
                        />
                      ))
                    ) : (
                      <div className="p-8 text-center text-gray-400 text-xs italic">
                        No recent notifications.
                      </div>
                    )}
                  </div>
                  <div className="p-3 bg-gray-50 border-t border-gray-100 text-center">
                    <button 
                      onClick={() => { setIsNotifOpen(false); setShowAllModal(true); }}
                      className="text-[10px] font-bold text-gray-500 hover:text-blue-600 uppercase tracking-widest transition-colors flex items-center justify-center mx-auto"
                    >
                      <ExternalLink className="w-3 h-3 mr-1.5" />
                      View All Notifications
                    </button>
                  </div>
                </div>
              )}
            </div>
            
            {/* Desktop User Info */}
            <div className="hidden md:flex items-center px-3 py-1 border border-gray-200 rounded-full bg-gray-50">
              <User className="w-4 h-4 mr-2 text-gray-500" />
              <div className="text-sm font-medium text-gray-700 mr-3 max-w-[120px] truncate">{user.name}</div>
              <button onClick={onLogout} className="text-gray-400 hover:text-red-500 transition-colors">
                <LogOut className="w-4 h-4" />
              </button>
            </div>

            {/* Mobile Menu Button */}
            <button 
              onClick={toggleMenu}
              className="md:hidden p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none"
            >
              {isMenuOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
            </button>
          </div>
        </div>
      </div>

      {/* View All Notifications Modal */}
      {showAllModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6">
          <div className="absolute inset-0 bg-gray-900/60 backdrop-blur-sm" onClick={() => setShowAllModal(false)}></div>
          <div className="relative bg-white w-full max-w-lg rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
            <div className="p-5 border-b border-gray-100 flex justify-between items-center bg-white sticky top-0">
              <div>
                <h2 className="text-lg font-bold text-gray-900">All Notifications</h2>
                <p className="text-xs text-gray-500 mt-0.5">Stay updated with your manufacturing status.</p>
              </div>
              <button 
                onClick={() => setShowAllModal(false)}
                className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="overflow-y-auto flex-1">
              {notifications.length > 0 ? (
                <div className="divide-y divide-gray-50">
                  {notifications.map(n => (
                    <NotificationItem 
                      key={n.id} 
                      notification={n} 
                      onClick={handleNotifClick} 
                      onDelete={handleDeleteNotif} 
                    />
                  ))}
                </div>
              ) : (
                <div className="p-20 text-center text-gray-400">
                  <Bell className="w-12 h-12 mx-auto mb-4 opacity-10" />
                  <p className="text-sm italic">You don't have any notifications.</p>
                </div>
              )}
            </div>
            <div className="p-4 border-t border-gray-50 bg-gray-50 text-right">
              <button 
                onClick={() => setShowAllModal(false)}
                className="px-6 py-2 text-sm font-bold text-gray-700 hover:text-gray-900 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="md:hidden bg-white border-b border-gray-200 py-2 px-4 space-y-1 shadow-lg">
          <Link 
            to="/" 
            onClick={() => setIsMenuOpen(false)}
            className="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:bg-gray-50"
          >
            <div className="flex items-center">
              <LayoutDashboard className="w-4 h-4 mr-3 text-blue-600" />
              Dashboard
            </div>
          </Link>
          {user.role === UserRole.CLIENT_USER && (
            <Link 
              to="/new-ticket" 
              onClick={() => setIsMenuOpen(false)}
              className="block px-3 py-2 rounded-md text-base font-medium text-gray-700 hover:bg-gray-50"
            >
              <div className="flex items-center">
                <PlusCircle className="w-4 h-4 mr-3 text-blue-600" />
                Raise Issue
              </div>
            </Link>
          )}
          <div className="pt-4 pb-3 border-t border-gray-100">
            <div className="flex items-center px-3">
              <div className="flex-shrink-0">
                <User className="h-8 w-8 rounded-full bg-gray-100 p-1.5 text-gray-500" />
              </div>
              <div className="ml-3">
                <div className="text-base font-medium text-gray-800">{user.name}</div>
                <div className="text-sm font-medium text-gray-500">{user.email}</div>
              </div>
            </div>
            <div className="mt-3 px-2 space-y-1">
              <button
                onClick={() => {
                  onLogout();
                  setIsMenuOpen(false);
                }}
                className="block w-full text-left px-3 py-2 rounded-md text-base font-medium text-red-600 hover:bg-red-50"
              >
                <div className="flex items-center">
                  <LogOut className="w-4 h-4 mr-3" />
                  Sign out
                </div>
              </button>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
};

const App = () => {
  const [user, setUser] = useState<UserType | null>(firebase.getCurrentUser());

  const handleLogin = (u: UserType) => setUser(u);
  const handleLogout = () => {
    firebase.logout();
    setUser(null);
  };

  if (!user) {
    return <LoginPage onLogin={handleLogin} />;
  }

  return (
    <HashRouter>
      <div className="min-h-screen bg-gray-50">
        <Navigation user={user} onLogout={handleLogout} />
        <main className="max-w-7xl mx-auto py-4 md:py-6 px-4 sm:px-6 lg:px-8">
          <Routes>
            <Route path="/" element={<Dashboard user={user} />} />
            <Route path="/ticket/:id" element={<TicketView user={user} />} />
            <Route path="/new-ticket" element={<NewTicket user={user} />} />
            <Route path="/create-user" element={<CreateUser />} />
            <Route path="*" element={<Navigate to="/" />} />
          </Routes>
        </main>
      </div>
    </HashRouter>
  );
};

export default App;
