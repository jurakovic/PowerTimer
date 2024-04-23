using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Diagnostics;
using Microsoft.Win32;
using System.Text.RegularExpressions;

namespace PowerTimer
{
	public partial class Form1 : Form
	{
		int countdownTime = 0;
		int timerTime = 0;
		bool textChangedByButton = false;

		private string appname = "Power Timer";
		private string regKeyFullPath = null;
		private string regKeyPath = null;

		private DateTime date;
		private DateTime selecteddate
		{
			get
			{
				return date;
			}

			set
			{
				date = value;
				populatedate();
			}
		}

		int defaultHourDelay = 1;

		public Form1()
		{
			InitializeComponent();

			txtHour.Tag = ValNum.VHour;
			txtMinute.Tag = ValNum.VMinute;
			txtSecond.Tag = ValNum.VSecond;


			regKeyFullPath = @"HKEY_CURRENT_USER\Software\" + appname;
			regKeyPath = @"Software\" + appname;
		}

		private void Form1_Load(object sender, EventArgs e)
		{
			//loadSettings();
			RegistryKey key = Registry.CurrentUser.OpenSubKey(regKeyPath, true);
			if (key != null)
			{
				cbRememberWinPos.Checked =
					Convert.ToBoolean((int)Registry.GetValue(regKeyFullPath, "rememberWinPos", 0));

				if (cbRememberWinPos.Checked)
				{
					this.Left = (int)Registry.GetValue(regKeyFullPath, "positionX", 0); ;
					this.Top = (int)Registry.GetValue(regKeyFullPath, "positionY", 0); ;
				}
				else
				{
					this.StartPosition = FormStartPosition.CenterScreen;
				}

				cbWarnZeroTime.Checked =
					Convert.ToBoolean((int)Registry.GetValue(regKeyFullPath, "warnZeroTime", 0));

				cbMinimizeToTray.Checked =
					Convert.ToBoolean((int)Registry.GetValue(regKeyFullPath, "minimizeToTray", 0));

				comboDefaultAction.SelectedIndex =
					(int)Registry.GetValue(regKeyFullPath, "defaultAction", 0);

				defaultHourDelay = (int)Registry.GetValue(regKeyFullPath, "defaultTimeDelay", 0);
				tbDefaultTimeDelay.Text = defaultHourDelay.ToString("00");

				selecteddate = DateTime.Now.AddHours(defaultHourDelay);

				updateTime();

				key.Close();
			}
		}

		private void populatedate()
		{
			txtHour.Text = selecteddate.Hour.ToString("00");
			txtMinute.Text = selecteddate.Minute.ToString("00");
			txtSecond.Text = selecteddate.Second.ToString("00");
		}

		private void btnStart_Click(object sender, EventArgs e)
		{
			if (btnStart.Text == "START")
			{
				if (btnOptions.Text == "▲")
				{
					this.Height = 113;
					btnOptions.Text = "▼";
				}

				if (tabControl.SelectedIndex == 0)
				{
					countdownTime = Convert.ToInt32(txtHour.Text) * 3600
							+ Convert.ToInt32(txtMinute.Text) * 60
							+ Convert.ToInt32(txtSecond.Text);
				}
				else
				{
					DateTime now = DateTime.Now;
					DateTime dt = new DateTime(now.Year, now.Month, now.Day,
								Convert.ToInt32(txtHour.Text),
								Convert.ToInt32(txtMinute.Text),
								Convert.ToInt32(txtSecond.Text));

					countdownTime = Convert.ToInt32((dt - now).TotalSeconds);

					if (countdownTime < 0)
					{
						dt = dt.AddDays(1);
						countdownTime = Convert.ToInt32((dt - now).TotalSeconds);
					}
				}

				if (countdownTime == 0)
				{
					if (cbWarnZeroTime.Checked)
					{
						if (MessageBox.Show("No time entered, selected action will be performed immediately, continue?", "Confirm",
							MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.No)
						{
							return;
						}
					}

					doWork(); return;

					// ili --timerTime; 
					//jer tamo kasnije ide ++ pa da bude ==
					//i izvrsit ce se nakon 1 sec, ili onako gore se izvrsi odma
				}

				foreach (Control con in this.Controls)
				{
					con.Enabled = false;
				}

				groupBox1.Enabled = false;

				btnStart.Enabled = true;
				btnStart.Text = "STOP";

				//writeTimeToTitlebar(countdownTime);

				timer1.Start();
			}
			else //if (btnStart.Text == "STOP")
			{
				timer1.Stop();
				timerTime = 0;

				//this.Text = "Power Timer";
				notifyIcon1.Text = "Power Timer";

				foreach (Control con in this.Controls)
				{
					con.Enabled = true;
				}

				groupBox1.Enabled = false;

				btnStart.Text = "START";
			}
		}


		private void timer1_Tick(object sender, EventArgs e)
		{
			//Console.Beep();
			timerTime++;
			writeTimeToTitlebar(countdownTime - timerTime);

			if (timerTime == countdownTime)
			{
				timer1.Stop();
				timerTime = 0;

				foreach (Control con in this.Controls)
				{
					con.Enabled = true;
				}

				groupBox1.Enabled = false;

				btnStart.Text = "START";
				//this.Text = "Power Timer";
				notifyIcon1.Text = "Power Timer";
				doWork();
			}
		}

		void writeTimeToTitlebar(int elapsedTime)
		{
			int h, m, s;

			h = elapsedTime / 3600;
			m = (elapsedTime / 60) % 60;
			s = elapsedTime % 60;

			textChangedByButton = true;
			txtHour.Text = h.ToString("00");
			textChangedByButton = true;
			txtMinute.Text = m.ToString("00");
			textChangedByButton = true;
			txtSecond.Text = s.ToString("00");

			string action = cbAction.Text + " after ";

			if (h > 0)
			{
				notifyIcon1.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
				return;
			}
			else if (m > 0)
			{
				notifyIcon1.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
				return;
			}
			else
			{
				notifyIcon1.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
				return;
			}
		}

		void doWork()
		{
			//MessageBox.Show("doWork()"); return;

			if (cbAction.Text == "Shutdown")
				doWorkWithCmd("-s -t 0");

			if (cbAction.Text == "Restart")
				doWorkWithCmd("-r -t 0");

			if (cbAction.Text == "Logoff")
				doWorkWithCmd("-l");

			if (cbAction.Text == "Lock")
				Process.Start(@"C:\WINDOWS\system32\rundll32.exe", "user32.dll,LockWorkStation");

			if (cbAction.Text == "Sleep")
				Application.SetSuspendState(PowerState.Suspend, true, true);

			if (cbAction.Text == "Hibernate")
				doWorkWithCmd("-h");
		}

		void doWorkWithCmd(string arg)
		{
			System.Diagnostics.Process process = new System.Diagnostics.Process();
			System.Diagnostics.ProcessStartInfo startInfo = new System.Diagnostics.ProcessStartInfo();
			startInfo.WindowStyle = System.Diagnostics.ProcessWindowStyle.Hidden;

			startInfo.FileName = "shutdown.exe";
			startInfo.Arguments = arg;

			process.StartInfo = startInfo;
			process.Start();
		}

		private void tabControl1_SelectedIndexChanged(object sender, EventArgs e)
		{
			updateTime();
		}

		private void textbox_KeyPress(object sender, KeyPressEventArgs e)
		{
			TextBox textbox = sender as TextBox;

			ValNum v = textbox.Tag as ValNum;

			if (v == null)
				throw new NullReferenceException("Textbox has no defined ValNum Tag");

			double minimum = v.DMin;
			double maximum = v.DMax;
			int decimals = v.Decimals;

			if (minimum > maximum)
				throw new Exception("Minimum can not be greather than maximum");

			bool negative = minimum < 0;
			string text;
			bool handle;

			if (e.KeyChar == ',')
				e.KeyChar = '.';

			if (textbox.SelectionLength > 0)
				text = textbox.Text.Replace(textbox.SelectedText, Char.IsControl(e.KeyChar) ? String.Empty : e.KeyChar.ToString());
			else
				text = textbox.Text + (Char.IsControl(e.KeyChar) ? String.Empty : e.KeyChar.ToString());

			string pattern = "^";

			if (negative)
				pattern += "-?";

			pattern += "[0-9]*$";

			if (decimals > 0)
			{
				pattern = "(" + pattern + ")|(^";

				if (negative)
					pattern += "-?";

				pattern += "[0-9]*([.][0-9]{0," + decimals + "})?$)";
			}

			handle = !Regex.IsMatch(text, pattern);
			double val = 0;
			double.TryParse(text, out val);

			if (Char.IsDigit(e.KeyChar) && !handle)
				handle = val < minimum;

			if (Char.IsDigit(e.KeyChar) && !handle)
				handle = val > maximum;

			e.Handled = handle;
		}

		private void btnOptions_Click(object sender, EventArgs e)
		{
			//normal size: 526; 113

			if (btnOptions.Text == "▼")
			{
				groupBox1.Enabled = true;
				btnOptions.Text = "▲";
				this.Height = 275;
			}
			else
			{
				this.Height = 113;
				btnOptions.Text = "▼";
				groupBox1.Enabled = false;
			}
		}

		private void Form1_FormClosing(object sender, FormClosingEventArgs e)
		{
			if (btnStart.Text == "STOP")
			{
				if (MessageBox.Show("If you close this application selected action will not be performed.\nAre you sure you want to continue?", "Confirm",
					MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.No)
				{
					e.Cancel = true;
				}
			}
		}

		private void cbDefaultAction_SelectedIndexChanged(object sender, EventArgs e)
		{
			cbAction.SelectedIndex = comboDefaultAction.SelectedIndex;
		}

		private void btnPlus_Click(object sender, EventArgs e)
		{
			defaultHourDelay = Convert.ToInt32(tbDefaultTimeDelay.Text.ToString());
			if (defaultHourDelay < 24) ++defaultHourDelay;

			tbDefaultTimeDelay.Text = defaultHourDelay.ToString("00");
			updateTime();
		}

		private void btnMinus_Click(object sender, EventArgs e)
		{
			defaultHourDelay = Convert.ToInt32(tbDefaultTimeDelay.Text.ToString());
			if (defaultHourDelay > 1) --defaultHourDelay;

			tbDefaultTimeDelay.Text = defaultHourDelay.ToString("00");
			updateTime();
		}

		void updateTime()
		{
			textChangedByButton = true;

			if (tabControl.SelectedIndex == 0)
			{
				if (defaultHourDelay == 24)
				{
					
					txtHour.Text = "23";
					txtMinute.Text = "59";
					txtSecond.Text = "59";
				}
				else
				{
					txtHour.Text = defaultHourDelay.ToString("00");
					txtMinute.Text = "00";
					txtSecond.Text = "00";
				}
			}
			else
			{
				txtHour.Text = (DateTime.Now.AddHours(defaultHourDelay).Hour).ToString("00");
				txtMinute.Text = DateTime.Now.Minute.ToString("00");
				txtSecond.Text = DateTime.Now.Second.ToString("00");
			}

			//jer nekad se ne promijeni text a flag se stavi na true pa kasnije bude problema
			textChangedByButton = false;
		}

		private void Form1_Resize(object sender, EventArgs e)
		{
			if (this.WindowState == FormWindowState.Minimized && cbMinimizeToTray.Checked)
			{
				notifyIcon1.Visible = true;
				this.ShowInTaskbar = false;
			}
		}

		private void notifyIcon1_MouseClick(object sender, MouseEventArgs e)
		{
			if (e.Button == MouseButtons.Left)
			{
				this.WindowState = FormWindowState.Normal;
				this.ShowInTaskbar = true;
				notifyIcon1.Visible = false;
			}
			else
			{
				contextMenuStrip1.Show();
			}
		}

		private void Form1_TextChanged(object sender, EventArgs e)
		{
			notifyIcon1.Text = this.Text;
		}

		private void toolStripMenuItem1_Click(object sender, EventArgs e)
		{
			this.WindowState = FormWindowState.Normal;
			this.ShowInTaskbar = true;
			notifyIcon1.Visible = false;
		}

		private void toolStripMenuItem2_Click(object sender, EventArgs e)
		{
			this.Close();
		}

		private void Form1_FormClosed(object sender, FormClosedEventArgs e)
		{
			//saveSettings();
			RegistryKey key = Registry.CurrentUser.CreateSubKey(regKeyPath);

			key.SetValue("rememberWinPos", Convert.ToInt32(cbRememberWinPos.Checked));
			key.SetValue("positionX", Convert.ToInt32(this.Left));
			key.SetValue("positionY", Convert.ToInt32(this.Top));
			key.SetValue("warnZeroTime", Convert.ToInt32(cbWarnZeroTime.Checked));
			key.SetValue("minimizeToTray", Convert.ToInt32(cbMinimizeToTray.Checked));
			key.SetValue("defaultAction", Convert.ToInt32(comboDefaultAction.SelectedIndex));
			key.SetValue("defaultTimeDelay", Convert.ToInt32(tbDefaultTimeDelay.Text));

			key.Close();
		}


		private void tbHour_KeyDown(object sender, KeyEventArgs e)
		{

		}
	}
}