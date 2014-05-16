"""Test the rules that protect AVU records having attributes with a
given prefix.
"""

import subprocess
import unittest

class AVUProtectTest(unittest.TestCase): #pylint: disable=R0904
    """Test Suite based on the unittest framework."""

    expcoll = ""
    testfile = ""
    attrprefix = "" # For example "http://testzone01/irods#"
    f = expcoll + "/" + testfile

    def listavus(self):
        """Print the AVUs for the test file."""
        ret = subprocess.call("imeta ls -d '" + self.f + "'", shell=True)
        self.assertEqual(ret, 0)

    def setUp(self): #pylint: disable=C0103
        """Setup done before each test is called."""

        if (self.expcoll == "" or 
            self.testfile == "" or 
            self.attrprefix == ""):
            print ("Edit source to specify collection, "
                   "temporary filename, "
                   "and attribute name prefix to use for testing.")
            exit()

#        ret = subprocess.call("ienv")
#        self.assertEqual(ret, 0)
#        ret = subprocess.call(["touch", self.testfile])
#        self.assertEqual(ret, 0)
#        ret = subprocess.call(["iput", self.testfile, self.expcoll])
#        self.assertEqual(ret, 0)

    def tearDown(self): #pylint: disable=C0103
        """Cleanup done aftr each test is called."""

#        ret = subprocess.call(["rm", self.testfile])
#        self.assertEqual(ret, 0)
#        ret = subprocess.call(["irm", self.f])
#        self.assertEqual(ret, 0)
        pass

    def test_01_disallow_add_nonadmin(self):
        """Do not allow non-admin users to add protected AVU."""

        ret = subprocess.call("imeta add -d '" 
                              + self.f 
                              + "' '" + self.attrprefix + "archive' 'true'",
                              shell=True)
        self.assertEqual(ret, 4)
        self.listavus()

    def test_02_allow_add_nonadmin(self):
        """Confirm non-protected AVUs can be added."""

        ret = subprocess.call("imeta add -d '" 
                              + self.f 
                              + "' 'T2T3' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

    def test_03_allow_rm_nonadmin(self):
        """Confirm non-protected AVUs can be removed."""

        ret = subprocess.call("imeta rm -d '" 
                              + self.f 
                              + "' 'T2T3' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

    def test_04_allow_mod_nonadmin(self):
        """Confirm non-protected AVUs can be modified."""

        ret = subprocess.call("imeta add -d '" 
                              + self.f 
                              + "' 'T4-1' 'nonadmin'", 
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

        ret = subprocess.call("imeta mod -d '" 
                              + self.f 
                              + "' 'T4-1' 'nonadmin' 'n:T4-2' 'v:nonadmin-2'",
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

        ret = subprocess.call("imeta rm -d '" 
                              + self.f 
                              + "' 'T4-2' 'nonadmin-2'",
                              shell=True)
        self.assertEqual(ret, 0)
        self.listavus()

if __name__ == '__main__':
    unittest.main()
