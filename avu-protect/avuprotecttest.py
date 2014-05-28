"""Test the rules that protect AVU records having attributes with a
given prefix.
"""

import ConfigParser
import subprocess
import unittest

class AVUProtectTest(unittest.TestCase): #pylint: disable=R0904
    """Test suite based on the unittest framework."""

    def __init__(self, *args, **kwargs):
        """Read configuration."""

        super(AVUProtectTest, self).__init__(*args, **kwargs)
        
        config = ConfigParser.RawConfigParser()
        config.read('avuprotecttest.cfg')
        self.rodspw = config.get('AVUProtectTest', 'admin_password')
        self.expcoll = config.get('AVUProtectTest', 'expcoll')
        self.testfile = config.get('AVUProtectTest', 'testfile')
        self.attrprefix = config.get('AVUProtectTest', 'attrprefix')
        self.fpath = self.expcoll + "/" + self.testfile

    def listavus(self):
        """Print the AVUs for the test file."""
        ret = subprocess.call("imeta ls -d '" + self.fpath + "'", shell=True)
        self.assertEqual(ret, 0)

    def listfiles(self):
        """Print the list of files in the collection."""
        ret = subprocess.call("ils '" + self.expcoll + "'", shell=True)
        self.assertEqual(ret, 0)

    def setUp(self): #pylint: disable=C0103
        """Setup done before each test is called."""

        if (self.rodspw == "" or
            self.expcoll == "" or 
            self.testfile == "" or 
            self.attrprefix == ""):
            print ("Edit avuprotesttest.cfg to specify collection, "
                   "temporary filename, "
                   "and attribute name prefix to use for testing.")
            exit()

        ret = subprocess.call("touch '" + self.testfile + "'", shell=True)
        self.assertEqual(ret, 0)
        ret = subprocess.call("iput '" 
                              + self.testfile + "' '" 
                              + self.expcoll + "'", 
                              shell=True)
        self.assertEqual(ret, 0)

    def tearDown(self): #pylint: disable=C0103
        """Cleanup done aftr each test is called."""

        ret = subprocess.call(["rm", self.testfile])
        self.assertEqual(ret, 0)
        ret = subprocess.call("irm -f '" + self.fpath + "'", shell=True)
        self.assertEqual(ret, 0)

    def test_01_disallow_add_nonadmin(self):
        """Do not allow non-admin users to add protected AVU."""

        ret = subprocess.call("imeta add -d '" 
                              + self.fpath 
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 4)

    def test_02_allow_add_nonadmin(self):
        """Confirm non-protected AVUs can be added."""

        ret = subprocess.call("imeta add -d '" 
                              + self.fpath 
                              + "' 'T2T3' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)

    def test_03_allow_rm_nonadmin(self):
        """Confirm non-protected AVUs can be removed."""

        # Add the non-protected AVU.

        ret = subprocess.call("imeta add -d '" 
                              + self.fpath 
                              + "' 'T2T3' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)

        # Remove the non-protected AVU.

        ret = subprocess.call("imeta rm -d '" 
                              + self.fpath 
                              + "' 'T2T3' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)

    def test_04_allow_mod_nonadmin(self):
        """Confirm non-protected AVUs can be modified."""

        # Add the non-protected AVU.

        ret = subprocess.call("imeta add -d '" 
                              + self.fpath 
                              + "' 'T4-1' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)

        # Modify the non-protected AVU.

        ret = subprocess.call("imeta mod -d '" 
                              + self.fpath 
                              + "' 'T4-1' 'nonadmin' 'n:T4-2' 'v:nonadmin-2'",
                              shell=True)
        self.assertEqual(ret, 0)

        # Remove the non-protected AVU.

        ret = subprocess.call("imeta rm -d '" 
                              + self.fpath 
                              + "' 'T4-2' 'nonadmin-2'",
                              shell=True)
        self.assertEqual(ret, 0)

    def test_05_allow_add_admin(self):
        """Confirm an admin can still add protected AVUs."""

        # Grant admin write permission on the test file.

        ret = subprocess.call("ichmod write rods '" 
                              + self.fpath 
                              + "'", 
                              shell=True)
        self.assertEqual(ret, 0)

        # Add the protected AVU.

        ret = subprocess.call("export irodsUserName='rods'; "
                              + "export irodsAuthScheme='password'; "
                              + "echo '" + self.rodspw + "' | iinit ; "
                              + "imeta add -d '"
                              + self.fpath
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

        # Remove the protected AVU.

        ret = subprocess.call("export irodsUserName='rods'; "
                              + "export irodsAuthScheme='password'; "
                              + "echo '" + self.rodspw + "' | iinit ; "
                              + "imeta rm -d '"
                              + self.fpath
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 0)

    def test_06_disallow_del_archive(self):
        """Prevent deletion of data objects having the archive AVU set."""

        # Grant admin write permission on the test file.

        ret = subprocess.call("ichmod write rods '" 
                              + self.fpath 
                              + "'", 
                              shell=True)
        self.assertEqual(ret, 0)

        # Add the protected AVU with archive set to true.

        ret = subprocess.call("export irodsUserName='rods'; "
                              + "export irodsAuthScheme='password'; "
                              + "echo '" + self.rodspw + "' | iinit ; "
                              + "imeta add -d '"
                              + self.fpath
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()
        
        # Verify that removal fails.

        ret = subprocess.call("irm -f '" + self.fpath + "'", shell=True)
        self.assertEqual(ret, 3)
        self.listfiles()

        # Remove the protected archive attribute.

        ret = subprocess.call("export irodsUserName='rods'; "
                              + "export irodsAuthScheme='password'; "
                              + "echo '" + self.rodspw + "' | iinit ; "
                              + "imeta rm -d '"
                              + self.fpath
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

if __name__ == '__main__':
    unittest.main()
