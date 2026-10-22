import React, { useState } from 'react';
import { 
  UserPlus, 
  LogIn, 
  ShieldCheck, 
  Lock, 
  X, 
  AlertCircle,
  Smartphone,
  Mail,
  User,
  Key
} from 'lucide-react';
import { RoleType } from '../types';
import './LoginModal.css';

export interface AuthUser {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  role: RoleType;
  jurisdictionRegionId?: string | null;
  twoFactorEnabled?: boolean;
}

interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
  onLoginSuccess: (user: AuthUser, token: string) => void;
}

export const LoginModal: React.FC<LoginModalProps> = ({ isOpen, onClose, onLoginSuccess }) => {
  const [tab, setTab] = useState<'citizen-register' | 'citizen-login' | 'admin-login'>('citizen-login');
  
  // Registration form
  const [regName, setRegName] = useState('');
  const [regIdentifier, setRegIdentifier] = useState('');
  const [regPassword, setRegPassword] = useState('');

  // Login form
  const [loginIdentifier, setLoginIdentifier] = useState('');
  const [loginPassword, setLoginPassword] = useState('');

  // 2FA state
  const [twoFactorPending, setTwoFactorPending] = useState(false);
  const [twoFactorTempToken, setTwoFactorTempToken] = useState('');
  const [twoFactorCode, setTwoFactorCode] = useState('849201');

  // Error/Success state
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleRegisterCitizen = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setLoading(true);

    const isEmail = regIdentifier.includes('@');

    try {
      const response = await fetch('/api/v1/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: regName,
          email: isEmail ? regIdentifier : undefined,
          phone: !isEmail ? regIdentifier : undefined,
          password: regPassword,
          role: 'CITIZEN'
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Registration failed');
      }

      onLoginSuccess(data.user, data.accessToken);
      onClose();
    } catch (err: any) {
      setErrorMsg(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setLoading(true);

    try {
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          emailOrPhone: loginIdentifier,
          password: loginPassword
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Invalid credentials');
      }

      // Check if 2FA is required (FR-4)
      if (data.requires2FA) {
        setTwoFactorPending(true);
        setTwoFactorTempToken(data.tempToken);
        if (data.demoOtp) setTwoFactorCode(data.demoOtp);
        return;
      }

      onLoginSuccess(data.user, data.accessToken);
      onClose();
    } catch (err: any) {
      setErrorMsg(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify2FA = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setLoading(true);

    try {
      const response = await fetch('/api/v1/auth/verify-2fa', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          tempToken: twoFactorTempToken,
          code: twoFactorCode
        })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message || 'Invalid 2FA code');
      }

      onLoginSuccess(data.user, data.accessToken);
      onClose();
    } catch (err: any) {
      setErrorMsg(err.message);
    } finally {
      setLoading(false);
    }
  };

  const fillQuickCredentials = (email: string, pass: string) => {
    setLoginIdentifier(email);
    setLoginPassword(pass);
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="login-modal-window" onClick={e => e.stopPropagation()}>
        <div className="login-modal-header">
          <div className="header-icon-title">
            <ShieldCheck className="brand-icon" />
            <div>
              <h3>ResQAI Authentication & Access Portal</h3>
              <p>Secure login with Argon2id encryption & Role-Based Authorization</p>
            </div>
          </div>
          <button className="close-btn" onClick={onClose} aria-label="Close">
            <X size={20} />
          </button>
        </div>

        {/* Tab Switcher */}
        {!twoFactorPending && (
          <div className="login-tabs">
            <button 
              className={`login-tab ${tab === 'citizen-login' ? 'active' : ''}`}
              onClick={() => { setTab('citizen-login'); setErrorMsg(null); }}
            >
              <LogIn size={16} /> Citizen Sign In
            </button>
            <button 
              className={`login-tab ${tab === 'citizen-register' ? 'active' : ''}`}
              onClick={() => { setTab('citizen-register'); setErrorMsg(null); }}
            >
              <UserPlus size={16} /> Create Citizen ID
            </button>
            <button 
              className={`login-tab ${tab === 'admin-login' ? 'active' : ''}`}
              onClick={() => { 
                setTab('admin-login'); 
                setErrorMsg(null); 
                fillQuickCredentials('admin@resqai.org', 'AdminPassword123!');
              }}
            >
              <Lock size={16} /> Government / Main Admin
            </button>
          </div>
        )}

        {/* Error notification */}
        {errorMsg && (
          <div className="auth-error-banner">
            <AlertCircle size={18} />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* 2FA Verification Form */}
        {twoFactorPending ? (
          <form className="auth-form" onSubmit={handleVerify2FA}>
            <div className="twofa-prompt-box">
              <Lock size={24} color="var(--color-warn)" />
              <div>
                <strong>Two-Factor Authentication Required (FR-4)</strong>
                <p>Enter the 6-digit verification code sent to your registered contact.</p>
              </div>
            </div>

            <div className="form-group">
              <label>6-Digit 2FA Code</label>
              <input 
                type="text" 
                value={twoFactorCode}
                onChange={e => setTwoFactorCode(e.target.value)}
                maxLength={6}
                className="twofa-code-input"
                required
              />
              <span className="demo-hint">💡 Demo 2FA code pre-filled for testing</span>
            </div>

            <div className="form-actions">
              <button type="button" className="secondary-btn" onClick={() => setTwoFactorPending(false)}>
                Back to Login
              </button>
              <button type="submit" className="primary-btn" disabled={loading}>
                {loading ? 'Verifying...' : 'Verify 2FA & Access Dashboard'}
              </button>
            </div>
          </form>
        ) : (
          <>
            {/* Tab 1: Citizen Login */}
            {tab === 'citizen-login' && (
              <form className="auth-form" onSubmit={handleLogin}>
                <div className="form-group">
                  <label>Email or Mobile Number</label>
                  <div className="input-with-icon">
                    <Mail size={18} />
                    <input 
                      type="text" 
                      placeholder="e.g. sunita.citizen@resqai.org or +919876543210"
                      value={loginIdentifier}
                      onChange={e => setLoginIdentifier(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Password</label>
                  <div className="input-with-icon">
                    <Key size={18} />
                    <input 
                      type="password" 
                      placeholder="••••••••"
                      value={loginPassword}
                      onChange={e => setLoginPassword(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <button type="submit" className="submit-auth-btn" disabled={loading}>
                  {loading ? 'Signing in...' : 'Sign In as Citizen'}
                </button>

                <div className="quick-fill-section">
                  <span>Quick Test Sign In:</span>
                  <button 
                    type="button" 
                    className="chip-btn"
                    onClick={() => fillQuickCredentials('sunita.citizen@resqai.org', 'Password123!')}
                  >
                    Demo Citizen (Sunita Devi)
                  </button>
                </div>
              </form>
            )}

            {/* Tab 2: Create Citizen ID (Register) */}
            {tab === 'citizen-register' && (
              <form className="auth-form" onSubmit={handleRegisterCitizen}>
                <div className="form-group">
                  <label>Full Name</label>
                  <div className="input-with-icon">
                    <User size={18} />
                    <input 
                      type="text" 
                      placeholder="e.g. Ramesh Kumar"
                      value={regName}
                      onChange={e => setRegName(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Mobile Number or Email</label>
                  <div className="input-with-icon">
                    <Smartphone size={18} />
                    <input 
                      type="text" 
                      placeholder="e.g. +91 98765 00000 or ramesh@example.com"
                      value={regIdentifier}
                      onChange={e => setRegIdentifier(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Create Secure Password</label>
                  <div className="input-with-icon">
                    <Key size={18} />
                    <input 
                      type="password" 
                      placeholder="At least 6 characters"
                      value={regPassword}
                      onChange={e => setRegPassword(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <button type="submit" className="submit-auth-btn" disabled={loading}>
                  {loading ? 'Creating Citizen ID...' : 'Create Citizen ID & Log In'}
                </button>
              </form>
            )}

            {/* Tab 3: Government / Main Admin Login */}
            {tab === 'admin-login' && (
              <form className="auth-form" onSubmit={handleLogin}>
                <div className="admin-portal-badge">
                  <Lock size={16} />
                  <span>Main Admin & Official Emergency Personnel Portal</span>
                </div>

                <div className="form-group">
                  <label>Official Email or Username</label>
                  <div className="input-with-icon">
                    <Mail size={18} />
                    <input 
                      type="text" 
                      value={loginIdentifier}
                      onChange={e => setLoginIdentifier(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <div className="form-group">
                  <label>Password</label>
                  <div className="input-with-icon">
                    <Key size={18} />
                    <input 
                      type="password" 
                      value={loginPassword}
                      onChange={e => setLoginPassword(e.target.value)}
                      required
                    />
                  </div>
                </div>

                <button type="submit" className="submit-auth-btn btn-admin" disabled={loading}>
                  {loading ? 'Authenticating...' : 'Sign In to Official Command'}
                </button>

                <div className="quick-fill-section">
                  <span>Quick Test Roles:</span>
                  <div className="quick-chips-grid">
                    <button 
                      type="button" 
                      className="chip-btn"
                      onClick={() => fillQuickCredentials('admin@resqai.org', 'AdminPassword123!')}
                    >
                      Main Admin (Rajesh DDO)
                    </button>
                    <button 
                      type="button" 
                      className="chip-btn"
                      onClick={() => fillQuickCredentials('meera.govt@resqai.org', 'GovtPassword123!')}
                    >
                      Govt Officer (Inspector Meera)
                    </button>
                    <button 
                      type="button" 
                      className="chip-btn"
                      onClick={() => fillQuickCredentials('arjun.rescue@resqai.org', 'RescuePassword123!')}
                    >
                      Responder (Team Lead Arjun)
                    </button>
                    <button 
                      type="button" 
                      className="chip-btn"
                      onClick={() => fillQuickCredentials('anita.ngo@resqai.org', 'NgoPassword123!')}
                    >
                      NGO Lead (Anita Sharma)
                    </button>
                    <button 
                      type="button" 
                      className="chip-btn"
                      onClick={() => fillQuickCredentials('auditor@resqai.org', 'AuditorPassword123!')}
                    >
                      Auditor (Suresh Verma)
                    </button>
                  </div>
                </div>
              </form>
            )}
          </>
        )}
      </div>
    </div>
  );
};
