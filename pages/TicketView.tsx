
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import {
  ArrowLeft,
  Send,
  Clock,
  User as UserIcon,
  Paperclip,
  Info,
  PlusCircle,
  XCircle,
  Zap
} from 'lucide-react';
import { firebase } from '../services/firebaseService';
import { Ticket, User, UserRole, TicketStatus, Comment } from '../types';
import { STATUS_COLORS, CATEGORY_ICONS } from '../constants';

const TicketView = ({ user }: { user: User }) => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [ticket, setTicket] = useState<Ticket | null>(null);
  const [comments, setComments] = useState<Comment[]>([]);
  const [newComment, setNewComment] = useState('');
  const [error, setError] = useState('');

  const loadData = async () => {
    if (!id) return;
    setError('');
    try {
      const t = await firebase.getTicketById(id);
      if (t) {
        setTicket(t);
        const c = await firebase.getComments(id);
        setComments(c);
      } else {
        navigate('/');
      }
    } catch (err: any) {
      console.error("Failed to load ticket data", err);
      setError('Failed to load ticket. Access denied or document missing.');
    }
  };

  useEffect(() => {
    loadData();
  }, [id, navigate]);

  if (error) {
    return (
      <div className="p-8 text-center">
        <div className="inline-block p-4 bg-red-50 text-red-700 rounded-lg border border-red-200">
          <XCircle className="w-8 h-8 mx-auto mb-2" />
          <h3 className="font-bold text-lg">Error</h3>
          <p>{error}</p>
          <button onClick={() => navigate('/')} className="mt-4 text-sm underline hover:text-red-800">
            Return to Dashboard
          </button>
        </div>
      </div>
    );
  }

  const handleStatusChange = async (status: TicketStatus) => {
    if (!ticket) return;
    try {
      await firebase.updateTicketStatus(ticket.id, status);
      await loadData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handlePostComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newComment.trim() || !ticket) return;

    await firebase.addComment(ticket.id, newComment);
    setNewComment('');
    await loadData();
  };

  const simulateReply = async () => {
    if (!ticket) return;
    await firebase.simulateStaffReply(ticket.id);
    await loadData();
  };

  if (!ticket) return <div className="p-8 text-center">Loading ticket details...</div>;

  const isManufacturer = [UserRole.SUPPORT_AGENT, UserRole.SUPERVISOR, UserRole.ADMIN].includes(user.role);
  const canClientComment = !isManufacturer && ticket.status !== TicketStatus.RESOLVED && ticket.status !== TicketStatus.CLOSED;
  const canAgentComment = isManufacturer && ticket.status !== TicketStatus.CLOSED;
  const showCommentForm = isManufacturer ? canAgentComment : canClientComment;

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 md:gap-8">
      {/* Main Content Column */}
      <div className="lg:col-span-2 space-y-6">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center space-x-3 md:space-x-4">
            <Link to="/" className="p-1.5 md:p-2 hover:bg-gray-100 rounded-full transition-colors">
              <ArrowLeft className="w-5 h-5 text-gray-600" />
            </Link>
            <div className="min-w-0">
              <p className="text-xs font-bold text-blue-600 tracking-wider mb-0.5">{ticket.id}</p>
              <h1 className="text-lg md:text-2xl font-bold text-gray-900 truncate">{ticket.subject}</h1>
            </div>
          </div>


        </div>

        {/* Ticket Header Metadata (Mobile Only) */}
        <div className="lg:hidden flex flex-wrap gap-2 mb-4">
          <span className={`px-2.5 py-1 text-[10px] font-bold rounded-lg border ${STATUS_COLORS[ticket.status]}`}>
            {ticket.status}
          </span>
          <span className="bg-white border border-gray-200 px-2.5 py-1 rounded-lg text-[10px] font-bold text-gray-600 flex items-center">
            {CATEGORY_ICONS[ticket.category]}
            <span className="ml-1.5">{ticket.category}</span>
          </span>
        </div>

        {/* Description Box */}
        <div className="bg-white p-5 md:p-6 rounded-xl border border-gray-200 shadow-sm">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4 pb-4 border-b border-gray-100 gap-2">
            <div className="flex items-center space-x-2 text-sm text-gray-500">
              <UserIcon className="w-4 h-4" />
              <span className="font-bold text-gray-700">{ticket.userName}</span>
              <span className="hidden sm:inline">reported in</span>
              <span className="hidden sm:flex items-center text-blue-600 font-medium">
                {CATEGORY_ICONS[ticket.category]}
                <span className="ml-1">{ticket.category}</span>
              </span>
            </div>
            <div className="text-[11px] md:text-xs text-gray-400 uppercase font-semibold">
              {new Date(ticket.createdAt).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}
            </div>
          </div>
          <p className="text-sm md:text-base text-gray-700 whitespace-pre-wrap leading-relaxed">
            {ticket.description}
          </p>
          {ticket.attachments.length > 0 && (
            <div className="mt-6 flex flex-wrap gap-2">
              {ticket.attachments.map((a, i) => (
                <a
                  key={i}
                  href={a}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center space-x-2 bg-gray-50 border border-gray-200 px-3 py-1.5 rounded-lg text-[10px] font-bold text-gray-600 hover:bg-gray-100 hover:text-blue-600 transition-colors"
                >
                  <Paperclip className="w-3 h-3" />
                  <span>Attachment {i + 1}</span>
                </a>
              ))}
            </div>
          )}
        </div>

        {/* Timeline */}
        <div className="space-y-4">
          <h3 className="text-base md:text-lg font-bold text-gray-900 flex items-center">
            <Clock className="w-4 h-4 md:w-5 md:h-5 mr-2 text-blue-600" />
            Communication Timeline
          </h3>
          <div className="space-y-4">
            {comments.map((comment) => (
              <div
                key={comment.id}
                className={`p-4 rounded-xl border ${comment.isSystemMessage
                  ? 'bg-gray-50 border-gray-100 italic text-center text-gray-500 text-[10px] md:text-xs'
                  : comment.userRole === UserRole.CLIENT_USER
                    ? 'bg-white border-gray-200 mr-4 md:mr-12 shadow-sm'
                    : 'bg-blue-50 border-blue-100 ml-4 md:ml-12 shadow-sm'
                  }`}
              >
                {!comment.isSystemMessage && (
                  <div className="flex justify-between items-center mb-1.5">
                    <span className="text-[11px] font-bold text-gray-800">{comment.userName}</span>
                    <span className="text-[9px] text-gray-400 font-medium">{new Date(comment.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                  </div>
                )}
                <p className="text-xs md:text-sm text-gray-700 leading-relaxed">{comment.text}</p>
              </div>
            ))}
          </div>

          {/* Comment Form */}
          {showCommentForm ? (
            <form onSubmit={handlePostComment} className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm mt-6">
              <textarea
                className="w-full border-none focus:ring-0 text-sm placeholder-gray-400 resize-none px-4 py-4"
                placeholder="Write your reply to the manufacturer..."
                rows={3}
                value={newComment}
                onChange={(e) => setNewComment(e.target.value)}
              />
              <div className="flex justify-between items-center mt-2 pt-3 border-t border-gray-50">
                <button type="button" className="p-2 text-gray-400 hover:text-blue-500 transition-colors">
                  <Paperclip className="w-5 h-5" />
                </button>
                <button
                  type="submit"
                  disabled={!newComment.trim()}
                  className="bg-blue-600 text-white px-5 py-2 rounded-lg text-sm font-bold hover:bg-blue-700 disabled:opacity-50 flex items-center shadow-sm transition-all active:scale-95"
                >
                  <Send className="w-3.5 h-3.5 mr-2" />
                  Reply
                </button>
              </div>
            </form>
          ) : (
            ticket.status === TicketStatus.RESOLVED && !isManufacturer && (
              <div className="bg-emerald-50 border border-emerald-100 p-5 md:p-6 rounded-xl flex flex-col space-y-4 mt-6">
                <div className="flex items-start space-x-3">
                  <Info className="w-5 h-5 text-emerald-600 flex-shrink-0 mt-0.5" />
                  <div className="text-xs md:text-sm text-emerald-900 leading-relaxed">
                    <p className="font-bold text-base md:text-lg mb-1">Issue Resolved</p>
                    <p>This ticket is resolved. Communication is locked. Raise a new ticket if in need of further assistance. Thank you !</p>
                  </div>
                </div>
                <div className="pt-2 border-t border-emerald-200 flex flex-col sm:flex-row gap-2">
                  <Link to="/new-ticket" className="inline-flex items-center justify-center font-bold text-white bg-emerald-600 hover:bg-emerald-700 px-6 py-2.5 rounded-lg transition-all shadow-md active:scale-95 text-sm">
                    <PlusCircle className="w-4 h-4 mr-2" />
                    Raise New Issue
                  </Link>
                </div>
              </div>
            )
          )}
        </div>
      </div>

      {/* Sidebar - Stacks on mobile */}
      <div className="space-y-6">
        {/* Status Card */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm">
          <h3 className="text-[11px] font-bold text-gray-400 uppercase tracking-widest mb-4">Ticket Lifecycle</h3>
          <div className="mb-6">
            <span className={`px-4 py-2.5 inline-flex text-xs leading-5 font-bold rounded-xl border w-full justify-center shadow-sm ${STATUS_COLORS[ticket.status]}`}>
              {ticket.status}
            </span>
          </div>

          <div className="space-y-2.5">
            <p className="text-[10px] font-bold text-gray-400 mb-2 uppercase tracking-widest">Management Actions</p>
            {isManufacturer ? (
              <div className="grid grid-cols-1 gap-2">
                <button onClick={() => handleStatusChange(TicketStatus.ACKNOWLEDGED)} className="w-full py-2 px-4 text-[11px] font-bold rounded-lg border border-gray-200 hover:bg-gray-50 text-gray-700 transition-colors">
                  Acknowledge
                </button>
                <button onClick={() => handleStatusChange(TicketStatus.IN_PROGRESS)} className="w-full py-2 px-4 text-[11px] font-bold rounded-lg border border-gray-200 hover:bg-gray-50 text-gray-700 transition-colors">
                  Progress Work
                </button>
                <button onClick={() => handleStatusChange(TicketStatus.WAITING_FOR_CLIENT)} className="w-full py-2 px-4 text-[11px] font-bold rounded-lg border border-gray-200 hover:bg-gray-50 text-gray-700 transition-colors">
                  Hold for Info
                </button>
                <button onClick={() => handleStatusChange(TicketStatus.RESOLVED)} className="w-full py-2.5 px-4 text-xs font-bold rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white shadow-md transition-all">
                  Resolve Ticket
                </button>
              </div>
            ) : (
              ticket.status !== TicketStatus.CLOSED && (
                <button
                  onClick={() => handleStatusChange(TicketStatus.CLOSED)}
                  className="w-full py-2.5 px-4 text-xs font-bold rounded-lg border border-red-200 text-red-600 hover:bg-red-50 transition-colors flex items-center justify-center"
                >
                  <XCircle className="w-4 h-4 mr-2" />
                  Cancel Ticket
                </button>
              )
            )}
          </div>
        </div>

        {/* Metadata Sidebar */}
        <div className="bg-white p-6 rounded-xl border border-gray-200 shadow-sm space-y-5">
          <div>
            <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest block mb-2">Reported on System</label>
            <div className="flex items-center text-xs font-bold text-gray-800 bg-blue-50/50 p-2.5 rounded-lg border border-blue-100">
              <Clock className="w-4 h-4 mr-2 text-blue-500" />
              {new Date(ticket.createdAt).toLocaleDateString([], { month: 'short', day: 'numeric', year: 'numeric' })}
            </div>
          </div>
          <div className="pt-4 border-t border-gray-50">
            <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest block mb-2">Originating Client</label>
            <div className="text-xs font-bold text-gray-900 border-l-4 border-blue-500 pl-3 py-1 bg-gray-50/50 rounded-r-lg">
              {ticket.clientName}
            </div>
            <p className="text-[10px] text-gray-400 mt-2 px-1">Managed by: {ticket.userName}</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TicketView;
