
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  Search,
  Filter,
  CheckCircle2,
  ArrowRight,
  Activity,
  UserPlus,
  Trash2
} from 'lucide-react';
import { firebase } from '../services/firebaseService';
import { Ticket, User, UserRole, TicketStatus } from '../types';
import { STATUS_COLORS } from '../constants';


const StatsCard = ({ title, value, icon: Icon, color, onClick, isActive }: any) => (
  <div
    onClick={onClick}
    className={`bg-white p-5 md:p-6 rounded-xl border transition-all cursor-pointer hover:translate-y-[-2px] hover:shadow-md ${isActive ? 'ring-2 ring-blue-500 border-blue-500 shadow-md transform translate-y-[-2px]' : 'border-gray-200 shadow-sm'}`}
  >
    <div className={`flex items-center`}>
      <div className={`p-3 rounded-lg ${color} mr-4`}>
        <Icon className="w-5 h-5 md:w-6 md:h-6" />
      </div>
      <div>
        <p className="text-xs md:text-sm font-medium text-gray-500 uppercase tracking-wider">{title}</p>
        <p className="text-xl md:text-2xl font-bold text-gray-900">{value}</p>
      </div>
    </div>
  </div>
);

const Dashboard = ({ user, showResolved = false }: { user: User, showResolved?: boolean }) => {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState<string>('All Statuses');
  const [loading, setLoading] = useState(true);

  // Helper to handle filter click
  const handleFilterClick = (status: string) => {
    // If clicking active filter, clear it (reset to All Statuses)
    if (filterStatus === status) {
      setFilterStatus('All Statuses');
    } else {
      setFilterStatus(status);
    }
  };

  useEffect(() => {
    const unsubscribe = firebase.subscribeToTickets((data) => {
      setTickets(data);
      setLoading(false);
    });
    return () => unsubscribe();
  }, [user]);

  const filteredTickets = tickets.filter(t => {
    const matchesSearch = t.subject.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.id.toLowerCase().includes(searchTerm.toLowerCase());

    // Status Filter Logic
    let matchesStatus = false;

    if (showResolved) {
      // In Resolved View: Only show RESOLVED or CLOSED
      if (filterStatus === 'All Statuses') {
        matchesStatus = t.status === TicketStatus.RESOLVED || t.status === TicketStatus.CLOSED;
      } else {
        matchesStatus = t.status === filterStatus;
      }
    } else {
      // In Active View
      if (user.role !== UserRole.CLIENT_USER && filterStatus !== 'All Statuses') {
        // Staff filter override: Show tickets matching filter regardless of Resolved/Closed state
        matchesStatus = t.status === filterStatus;
      } else {
        // Default Logic (Clients or No Filter): Show ONLY Active tickets
        const isActive = t.status !== TicketStatus.RESOLVED && t.status !== TicketStatus.CLOSED;

        if (filterStatus === 'All Statuses') {
          matchesStatus = isActive;
        } else {
          matchesStatus = isActive && t.status === filterStatus;
        }
      }
    }

    return matchesSearch && matchesStatus;
  });

  // Soft Delete Handler
  const handleDeleteTicket = async (e: React.MouseEvent, ticketId: string) => {
    e.preventDefault(); // Prevent navigation
    if (window.confirm('Are you sure you want to delete this ticket from your history?')) {
      await firebase.deleteTicket(ticketId);
    }
  };

  const stats = {
    open: tickets.filter(t => t.status !== TicketStatus.CLOSED && t.status !== TicketStatus.RESOLVED).length,
    resolved: tickets.filter(t => t.status === TicketStatus.RESOLVED).length
  };

  return (
    <div className="space-y-6 md:space-y-8">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div className="flex-1 min-w-0">
          <h2 className="text-xl md:text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            {showResolved
              ? 'Resolved History'
              : (user.role === UserRole.CLIENT_USER ? `${user.clientName} Dashboard` : 'Manufacturer Support Center')}
          </h2>
          <p className="mt-1 text-xs md:text-sm text-gray-500">
            {showResolved
              ? `Archived records of ${stats.resolved} completed issues.`
              : `Welcome back, ${user.name}. Monitoring ${stats.open} active manufacturing issues.`}
          </p>
        </div>
        <div className="flex-shrink-0 flex gap-2">
          {user.role === UserRole.CLIENT_USER && (
            <Link
              to="/new-ticket"
              className="inline-flex items-center justify-center w-full md:w-auto px-6 py-2.5 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-blue-600 hover:bg-blue-700 focus:outline-none transition-all active:scale-95"
            >
              Raise New Issue
            </Link>
          )}
          {(user.role === UserRole.SUPPORT_AGENT || user.role === UserRole.ADMIN || user.role === UserRole.SUPERVISOR) && (
            <Link
              to="/create-user"
              className="inline-flex items-center justify-center w-full md:w-auto px-6 py-2.5 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-emerald-600 hover:bg-emerald-700 focus:outline-none transition-all active:scale-95"
            >
              <UserPlus className="w-4 h-4 mr-2" />
              Create User
            </Link>
          )}
        </div>
      </div>

      <div className="space-y-6 md:space-y-8">
        {/* Stats Grid */}
        {user.role === UserRole.CLIENT_USER ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 md:gap-5">
            {/* Kept Client view as Links for now, or convert to filters if desired?
                User request specifically mentioned "Staff accounts the buttons must act as filters".
                I will keep Client as Links (StatsCard wrapped in Link) as per previous design unless specified.
            */}
            <Link to="/" className="block">
              <StatsCard title="Open Tickets" value={stats.open} icon={Activity} color={`bg-blue-50 text-blue-600 ${!showResolved ? 'ring-2 ring-blue-500 ring-offset-2' : 'opacity-60 grayscale'}`} />
            </Link>
            <Link to="/resolved" className="block">
              <StatsCard title="Resolved Issues" value={stats.resolved} icon={CheckCircle2} color={`bg-emerald-50 text-emerald-600 ${showResolved ? 'ring-2 ring-emerald-500 ring-offset-2' : ''}`} />
            </Link>
          </div>
        ) : (
          <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3">
            <StatsCard
              title="New"
              value={tickets.filter(t => t.status === TicketStatus.NEW).length}
              icon={Activity}
              color={STATUS_COLORS[TicketStatus.NEW]}
              onClick={() => handleFilterClick(TicketStatus.NEW)}
              isActive={filterStatus === TicketStatus.NEW}
            />
            <StatsCard
              title="Ack."
              value={tickets.filter(t => t.status === TicketStatus.ACKNOWLEDGED).length}
              icon={CheckCircle2}
              color={STATUS_COLORS[TicketStatus.ACKNOWLEDGED]}
              onClick={() => handleFilterClick(TicketStatus.ACKNOWLEDGED)}
              isActive={filterStatus === TicketStatus.ACKNOWLEDGED}
            />
            <StatsCard
              title="In Prog."
              value={tickets.filter(t => t.status === TicketStatus.IN_PROGRESS).length}
              icon={Activity}
              color={STATUS_COLORS[TicketStatus.IN_PROGRESS]}
              onClick={() => handleFilterClick(TicketStatus.IN_PROGRESS)}
              isActive={filterStatus === TicketStatus.IN_PROGRESS}
            />
            <StatsCard
              title="Hold"
              value={tickets.filter(t => t.status === TicketStatus.HOLD_FOR_INFO).length}
              icon={Activity}
              color={STATUS_COLORS[TicketStatus.HOLD_FOR_INFO]}
              onClick={() => handleFilterClick(TicketStatus.HOLD_FOR_INFO)}
              isActive={filterStatus === TicketStatus.HOLD_FOR_INFO}
            />
            <StatsCard
              title="Resolved"
              value={tickets.filter(t => t.status === TicketStatus.RESOLVED).length}
              icon={CheckCircle2}
              color={STATUS_COLORS[TicketStatus.RESOLVED]}
              onClick={() => handleFilterClick(TicketStatus.RESOLVED)}
              isActive={filterStatus === TicketStatus.RESOLVED}
            />
            <StatsCard
              title="Closed"
              value={tickets.filter(t => t.status === TicketStatus.CLOSED).length}
              icon={CheckCircle2}
              color={STATUS_COLORS[TicketStatus.CLOSED]}
              onClick={() => handleFilterClick(TicketStatus.CLOSED)}
              isActive={filterStatus === TicketStatus.CLOSED}
            />
          </div>
        )}

        {/* Search Bar (Dropdown Removed) */}
        <div className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm flex flex-col md:flex-row gap-4">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-2.5 h-4 w-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by ID or Subject..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 text-sm"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>
        </div>

        {/* Ticket List - Mobile Optimized Table */}
        <div className="bg-white shadow-sm border border-gray-200 rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 md:px-6 py-3 text-left text-[10px] md:text-xs font-bold text-gray-500 uppercase tracking-wider">Ticket</th>
                  <th className="hidden sm:table-cell px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Client</th>
                  <th className="px-4 md:px-6 py-3 text-left text-[10px] md:text-xs font-bold text-gray-500 uppercase tracking-wider">Status</th>
                  <th className="hidden lg:table-cell px-6 py-3 text-left text-xs font-bold text-gray-500 uppercase tracking-wider">Activity</th>
                  <th className="px-4 md:px-6 py-3 text-right text-[10px] md:text-xs font-bold text-gray-500 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {loading ? (
                  <tr><td colSpan={5} className="px-6 py-10 text-center text-gray-500 italic">Accessing database...</td></tr>
                ) : filteredTickets.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-10 text-center text-gray-500 italic">No tickets found.</td></tr>
                ) : filteredTickets.map((ticket) => (
                  <tr key={ticket.id} className="hover:bg-gray-50 transition-colors group">
                    <td className="px-4 md:px-6 py-4 whitespace-nowrap">
                      <div className="flex flex-col">
                        <span className="text-xs md:text-sm font-bold text-blue-600">{ticket.id}</span>
                        <span className="text-xs md:text-sm text-gray-900 font-medium truncate max-w-[120px] md:max-w-xs">{ticket.subject}</span>
                        <span className="sm:hidden text-[10px] text-gray-400 truncate">{ticket.clientName}</span>
                      </div>
                    </td>
                    <td className="hidden sm:table-cell px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900 font-semibold">{ticket.clientName}</div>
                      <div className="text-xs text-gray-500">{ticket.userName}</div>
                    </td>
                    <td className="px-4 md:px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 py-0.5 inline-flex text-[10px] md:text-[11px] leading-5 font-bold rounded-full border ${STATUS_COLORS[ticket.status]}`}>
                        {ticket.status}
                      </span>
                    </td>
                    <td className="hidden lg:table-cell px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(ticket.updatedAt).toLocaleDateString()}
                    </td>
                    <td className="px-4 md:px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <Link to={`/ticket/${ticket.id}`} className="text-blue-600 hover:text-blue-900 flex items-center justify-end font-bold transition-all">
                        <span className="hidden md:inline">View</span>
                        <ArrowRight className="w-4 h-4 ml-1 group-hover:translate-x-1 transition-transform" />
                      </Link>

                      {/* Delete Action for Resolved/Closed Tickets */}
                      {(ticket.status === TicketStatus.RESOLVED || ticket.status === TicketStatus.CLOSED) && (
                        <button
                          onClick={(e) => handleDeleteTicket(e, ticket.id)}
                          className="ml-4 text-gray-400 hover:text-red-500 transition-colors p-1"
                          title="Delete from history"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
