
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Package2, Send, AlertCircle, Upload } from 'lucide-react';
import { firebase } from '../services/firebaseService';
import { User, TicketCategory } from '../types';

const NewTicket = ({ user }: { user: User }) => {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    subject: '',
    description: '',
    category: TicketCategory.TECHNICAL_SUPPORT
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      const ticket = await firebase.createTicket(formData);
      navigate(`/ticket/${ticket.id}`);
    } catch (err) {
      alert('Failed to create ticket');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white shadow-xl rounded-2xl border border-gray-100 overflow-hidden">
        <div className="bg-blue-600 p-8 text-white">
          <div className="flex items-center space-x-3 mb-2">
            <Package2 className="w-8 h-8" />
            <h1 className="text-2xl font-bold">Raise New Issue</h1>
          </div>
          <p className="text-blue-100 opacity-90">
            Describe the problem or request and our support team will get back to you as soon as possible.
          </p>
        </div>
        
        <form onSubmit={handleSubmit} className="p-8 space-y-6">
          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">Category</label>
            <select 
              className="w-full border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 text-sm py-2.5"
              value={formData.category}
              onChange={(e) => setFormData({...formData, category: e.target.value as TicketCategory})}
            >
              {Object.values(TicketCategory).map(c => <option key={c} value={c}>{c}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">Subject</label>
            <input
              type="text"
              required
              className="w-full border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 text-sm py-2.5"
              placeholder="e.g., Damaged items in Shipment #592"
              value={formData.subject}
              onChange={(e) => setFormData({...formData, subject: e.target.value})}
            />
          </div>

          <div>
            <label className="block text-sm font-bold text-gray-700 mb-2">Detailed Description</label>
            <textarea
              required
              rows={5}
              className="w-full border-gray-300 rounded-lg focus:ring-blue-500 focus:border-blue-500 text-sm py-2.5"
              placeholder="Please provide as much detail as possible, including batch numbers, order dates, and symptoms..."
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
            />
          </div>

          <div className="p-4 bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl text-center">
            <Upload className="mx-auto h-8 w-8 text-gray-400 mb-2" />
            <p className="text-sm text-gray-600 font-medium">Click to upload or drag and drop</p>
            <p className="text-xs text-gray-500">PNG, JPG, PDF up to 10MB</p>
          </div>

          <div className="flex items-start space-x-3 bg-blue-50 p-4 rounded-xl">
            <AlertCircle className="w-5 h-5 text-blue-600 flex-shrink-0" />
            <p className="text-xs text-blue-800 leading-relaxed">
              Submitting this ticket will notify our Response Team. 
              Our average first response time is <b>within 24-48 hours</b>.
            </p>
          </div>

          <div className="pt-4 flex items-center justify-end space-x-4">
            <button
              type="button"
              onClick={() => navigate('/')}
              className="px-6 py-2.5 text-sm font-medium text-gray-700 hover:text-gray-900"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={loading}
              className="bg-blue-600 text-white px-8 py-2.5 rounded-lg text-sm font-bold hover:bg-blue-700 shadow-lg shadow-blue-200 disabled:opacity-50 flex items-center"
            >
              <Send className="w-4 h-4 mr-2" />
              {loading ? 'Submitting...' : 'Submit Ticket'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default NewTicket;
