program MorseRunner;

uses
  Forms,
  Main in 'Main.pas' {MainForm},
  Contest in 'Contest.pas',
  DualExchContest in 'DualExchContest.pas',
  RndFunc in 'RndFunc.pas',
  Ini in 'Ini.pas',
  Station in 'Station.pas',
  MorseKey in 'VCL\MorseKey.pas',
  FarnsKeyer in 'VCL\FarnsKeyer.pas',
  StnColl in 'StnColl.pas',
  DxStn in 'DxStn.pas',
  MyStn in 'MyStn.pas',
  CallLst in 'CallLst.pas',
  QrmStn in 'QrmStn.pas',
  Log in 'Log.pas',
  Qsb in 'Qsb.pas',
  DxOper in 'DxOper.pas',
  QrnStn in 'QrnStn.pas',
  ScoreDlg in 'ScoreDlg.pas' {ScoreDialog},
  BaseComp in 'VCL\BaseComp.pas',
  PermHint in 'VCL\PermHint.pas',
  Crc32 in 'VCL\Crc32.pas',
  SndCustm in 'VCL\SndCustm.pas',
  SndTypes in 'VCL\SndTypes.pas',
  SndOut in 'VCL\SndOut.pas',
  MorseTbl in 'VCL\MorseTbl.pas',
  QuickAvg in 'VCL\QuickAvg.pas',
  MovAvg in 'VCL\MovAvg.pas',
  Mixers in 'VCL\Mixers.pas',
  VolumCtl in 'VCL\VolumCtl.pas',
  VolmSldr in 'VCL\VolmSldr.pas',
  WavFile in 'VCL\WavFile.pas',
  pcre in 'PerlRegEx\pcre.pas',
  PerlRegEx in 'PerlRegEx\PerlRegEx.pas',
  ARRL in 'ARRL.pas',
  ArrlFd in 'ArrlFd.pas',
  NaQp in 'NaQp.pas',
  CWOPS in 'CWOPS.pas',
  CqWW in 'CqWW.pas',
  CqWpx in 'CqWpx.pas',
  ArrlDx in 'ArrlDx.pas',
  CWSST in 'CWSST.pas',
  ALLJA in 'ALLJA.pas',
  ACAG in 'ACAG.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Morse Runner';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

