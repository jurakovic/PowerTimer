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

namespace Power_Timer
{
    public partial class Form1 : Form
    {
        int countdownTime = 0;
        int timerTime = 0;
        bool textChangedByButton = false;

        private string appname = "Power Timer";
        private string regKeyFullPath = null;
        private string regKeyPath = null;

        int defaultHourDelay = 1;

        public Form1()
        {
            InitializeComponent();
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
                updateTime();

                key.Close();
            }
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

                if (radioButtonCountdown.Checked)
                {
                    countdownTime = Convert.ToInt32(tbHour.Text) * 3600
                            + Convert.ToInt32(tbMin.Text) * 60
                            + Convert.ToInt32(tbSec.Text);
                }
                else
                {
                    DateTime now = DateTime.Now;
                    DateTime dt = new DateTime(now.Year, now.Month, now.Day,
                                Convert.ToInt32(tbHour.Text),
                                Convert.ToInt32(tbMin.Text),
                                Convert.ToInt32(tbSec.Text));

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

            h = elapsedTime/3600;
            m = (elapsedTime / 60) % 60;
            s = elapsedTime % 60;

            textChangedByButton = true;
            tbHour.Text = h.ToString("00");
            textChangedByButton = true;
            tbMin.Text = m.ToString("00");
            textChangedByButton = true;
            tbSec.Text = s.ToString("00");

            string action = cbAction.Text + " after ";

            if (h > 0)
            {
                //this.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
                notifyIcon1.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
                return;
            }
            else if (m > 0)
            {
                //this.Text = "Power Timer - " + action + m.ToString("00") + " m " + s.ToString("00") + " s";
                notifyIcon1.Text = "Power Timer - " + action + h.ToString("00") + " h " + m.ToString("00") + " m " + s.ToString("00") + " s";
                return;
            }
            else
            {
                //this.Text = "Power Timer - " + action + s.ToString("00") + " s";
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

        private void radioButton_CheckedChanged(object sender, EventArgs e)
        {
            //radioButtonCountdown.FlatStyle = FlatStyle.Standard;
            //radioButtonAtTime.FlatStyle = FlatStyle.Standard;
            //(sender as RadioButton).FlatStyle = FlatStyle.Popup;

            updateTime();
        }
        
        private void textbox_KeyPress(object sender, KeyPressEventArgs e)
        {
            bool handle = true;
            
            if (char.IsDigit(e.KeyChar) == true)
            {
                TextBox tb = sender as TextBox;

                if (tb.Name == "tbHour")
                    handle = !checkValue(tb.Text, e, tb.SelectionStart, 23);
                else
                    handle = !checkValue(tb.Text, e, tb.SelectionStart, 59);
            }

            e.Handled = handle; // broj se upisuje za false
        }

        private void textbox_Enter(object sender, EventArgs e)
        {
            ((TextBox)sender).Select(0, 1);
        }

        private void textbox_TextChanged(object sender, EventArgs e)
        {
            if (textChangedByButton)
            {
                //da se ne prebacuje fokus ako se povecava preko gumba,
                //nego samo ako se rucno upisuje
                textChangedByButton = false;
                return;
            }

            TextBox tb = sender as TextBox;

            if (tb.SelectionStart == 1)
            {
                tb.Select(1, 1);
            }
            else
            {
                if (tb.Name == "tbHour") 
                    tbMin.Focus();
                else if (tb.Name == "tbMin") 
                    tbSec.Focus();
                else 
                    cbAction.Focus();
            }
        }

        private void textbox_MouseClick(object sender, MouseEventArgs e)
        {
            if ((sender as TextBox).SelectionStart == 2) (sender as TextBox).SelectionStart = 1;
            
            (sender as TextBox).Select((sender as TextBox).SelectionStart, 1);
        }

        bool checkValue(string str, KeyPressEventArgs e, int index, int maxValue)
        {
            bool ret = false;
            int val = 0;

            if (index == 0)
            {
                if (e.KeyChar.ToString() == "2")
                {
                    //ako se unosi 2, a trenutno pise npr 19, onda ce se upisat 20 i prebacit fokus na 0
                    //ako pise 13, samo ce se upisat 2, pa ce bit 23

                    val = Convert.ToInt32(e.KeyChar.ToString() + str[1]);

                    if (val > 23)
                    {
                        textChangedByButton = true;
                        tbHour.Text = "20";
                        tbHour.Select(1, 1);
                        return false;
                    }
                }
                else 
                    val = Convert.ToInt32(e.KeyChar.ToString() + str[1]);
            }
            else
                val = Convert.ToInt32(str[0] + e.KeyChar.ToString());

            if (val <= maxValue)
                ret = true;

            return ret;
        }

        private void btnUpDown_Click(object sender, EventArgs e)
        {
            Button bt = sender as Button;
            textChangedByButton = true;

            if (bt.Name == "hourUp")
            {
                int hour = Convert.ToInt32(tbHour.Text);
                if (hour < 23) ++hour;
                else hour = 0;
                tbHour.Text = hour.ToString("00");
            }
            else if (bt.Name == "hourDown")
            {
                int hour = Convert.ToInt32(tbHour.Text);
                if (hour > 0) --hour;
                else hour = 23;
                tbHour.Text = hour.ToString("00"); 
            }
            else if (bt.Name == "minUp")
            {
                int min = Convert.ToInt32(tbMin.Text);
                if (min < 59) ++min;
                else min = 00;
                tbMin.Text = min.ToString("00");
            }
            else if (bt.Name == "minDown")
            {
                int min = Convert.ToInt32(tbMin.Text);
                if (min > 0) --min;
                else min = 59;
                tbMin.Text = min.ToString("00");
            }
            else if (bt.Name == "secUp")
            {
                int sec = Convert.ToInt32(tbSec.Text);
                if (sec < 59) ++sec;
                else sec = 00;
                tbSec.Text = sec.ToString("00");
            }
            else if (bt.Name == "secDown")
            {
                int sec = Convert.ToInt32(tbSec.Text);
                if (sec > 0) --sec;
                else sec = 59;
                tbSec.Text = sec.ToString("00");
            }

            bt.Focus();
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
            if (radioButtonCountdown.Checked)
            {
                if (defaultHourDelay == 24)
                {
                    textChangedByButton = true;
                    tbHour.Text = "23";
                    textChangedByButton = true;
                    tbMin.Text = "59";
                    textChangedByButton = true;
                    tbSec.Text = "59";
                }
                else
                {
                    textChangedByButton = true;
                    tbHour.Text = defaultHourDelay.ToString("00");
                    textChangedByButton = true;
                    tbMin.Text = "00";
                    textChangedByButton = true;
                    tbSec.Text = "00";
                }
            }
            else
            {
                textChangedByButton = true;
                tbHour.Text = (DateTime.Now.AddHours(defaultHourDelay).Hour).ToString("00");
                textChangedByButton = true;
                tbMin.Text = DateTime.Now.Minute.ToString("00");
                textChangedByButton = true;
                tbSec.Text = DateTime.Now.Second.ToString("00");
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


    }
}