# Protect AVUs from being modified by the user. Based on code from
# Tony Edgin posted to the iRODS-Chat Group Group May 2, 2014, online
# https://groups.google.com/d/msg/irod-chat/UXoVHgsu_ic/lq52F3QJocMJ

msiSetAVU(*ItemType, *ItemName, *A, *V, *U) {

  # TODO: This needs to be implemented for the COPY case.

}

avuProtected(*A) {
  if (*A like "http://testzone01/irods#*") {
    true
  }
  else {
    false
  } 
}

isRodsAdmin(*A) {
  if (*A == "rods") {
    true
  }
  else {
    false
  }
}

# If an AVU is not protected, it sets the AVU to the given item

setAVUIfUnprotected(*ItemType, *ItemName, *A, *V, *U) {
  if (!avuProtected(*A)) {
    msiSetAVU(*ItemType, *ItemName, *A, *V, *U);
  }
}

# Copies the unprotected AVUs from a given collection to the given
# item.

cpUnprotectedCollAVUs(*Coll, *TargetType, *TargetName) =
  foreach (*avu in SELECT META_COLL_ATTR_NAME, META_COLL_ATTR_VALUE, META_COLL_ATTR_UNITS
                     WHERE COLL_NAME == *Coll) {
    setAVUIfUnprotected(*TargetType, *TargetName, *avu.META_COLL_ATTR_NAME,
                        *avu.META_COLL_ATTR_VALUE, *avu.META_COLL_ATTR_UNITS);
  }

# Copies the unprotected AVUs from a given data object to the given
# item.

cpUnprotectedDataObjAVUs(*ObjPath, *TargetType, *TargetName) {
  msiSplitPath(*ObjPath, *parentColl, *objName);
  foreach (*avu in SELECT META_DATA_ATTR_NAME, META_DATA_ATTR_VALUE, META_DATA_ATTR_UNITS
                     WHERE COLL_NAME == *parentColl AND DATA_NAME == *objName) {
    setAVUIfUnprotected(*TargetType, *TargetName, *avu.META_DATA_ATTR_NAME,
                        *avu.META_DATA_ATTR_VALUE, *avu.META_DATA_ATTR_UNITS);
  }
}

# Copies the unprotected AVUs from a given resource to the given item.

cpUnprotectedRescAVUs(*Resc, *TargetType, *TargetName) =
  foreach (*avu in SELECT META_RESC_ATTR_NAME, META_RESC_ATTR_VALUE, META_RESC_ATTR_UNITS
                     WHERE RESC_NAME == *Resc) {
    setAVUIfUnprotected(*TargetType, *TargetName, *avu.META_RESC_ATTR_NAME,
                        *avu.META_RESC_ATTR_VALUE, *avu.META_RESC_ATTR_UNITS);
  }

# Copies the unprotected AVUs from a given resource group to the given
# item.

cpUnprotectedRescGrpAVUs(*Grp, *TargetType, *TargetName) =
  foreach (*avu in SELECT META_RESC_GROUP_ATTR_NAME, META_RESC_GROUP_ATTR_VALUE,
                          META_RESC_GROUP_ATTR_UNITS
                     WHERE RESC_GROUP_NAME == *Grp) {
    setAVUIfUnprotected(*TargetType, *TargetName, *avu.META_RESC_GROUP_ATTR_NAME,
                        *avu.META_RESC_GROUP_ATTR_VALUE, *avu.META_RESC_GROUP_ATTR_UNITS);
  }

# Copies the unprotected AVUs from a given user to the given item.

cpUnprotectedUserAVUs(*User, *TargetType, *TargetName) =
  foreach (*avu in SELECT META_USER_ATTR_NAME, META_USER_ATTR_VALUE, META_USER_ATTR_UNITS
                     WHERE USER_NAME == *User) {
    setAVUIfUnprotected(*TargetType, *TargetName, *avu.META_RESC_ATTR_NAME,
                        *avu.META_RESC_ATTR_VALUE, *avu.META_RESC_ATTR_UNITS);
  }


# ADD or REMOVE - Only administrators can add or remove metadata in
# the irods namespace.

acPreProcForModifyAVUMetadata(*Option,*ItemType,*ItemName,*AName,*AValue,*AUnit) { 

  if ( (!isRodsAdmin($userNameClient) &&
        avuProtected(*AName)) ) {
    cut;
    failmsg(-1, "Rejected change of " ++ *AName ++ " for " ++ *ItemName ++ " by " ++ $userNameClient ++ ". Protected attributes can only be changed by administrators.");
  }

}

# MODIFY - Disallow change to something in the protected
# namespace. Disallow change from protected namespace to something
# else.

acPreProcForModifyAVUMetadata(*Option,
			      *ItemType,
			      *ItemName,
			      *AName,
			      *AValue,
			      *AUnit, 
			      *NAName, 
			      *NAValue, 
			      *NAUnit) {
  if ( 
       ( !isRodsAdmin($userNameClient) &&
         ( avuProtected(*AName) || avuProtected(*NAName) )
       )
     ) {
    cut;
    failmsg(-1, "Rejected change from " ++ *AName ++ " to " ++ *NAName ++ " for " ++ *ItemName ++ " by $userNameClient. Protected attributes can only be changed by administrators.");
  }

}

# COPY - This rule ensures that only the non-protected AVUs are copied from
# one item to another.

acPreProcForModifyAVUMetadata(*Option, 
		              *SourceItemType, 
			      *TargetItemType, 
			      *SourceItemName,
                              *TargetItemName) {
  if (!isRodsAdmin($userNameClient)) {
    if (*SourceItemType == '-c') {
      cpUnprotectedCollAVUs(*SourceItemName, *TargetItemType, *TargetItemName);
    } else if (*SourceItemType == '-d') {
      cpUnprotectedDataObjAVUs(*SourceItemName, *TargetItemType, *TargetItemName);
    } else if (*SourceItemType == '-g') {
      cpUnprotectedRescGrpAVUs(*SourceItemName, *TargetItemType, *TargetItemName);
    } else if (*SourceItemType == '-r') {
      cpUnprotectedRescAVUs(*SourceItemName, *TargetItemType, *TargetItemName);
    } else if (*SourceItemType == '-u') {
      cpUnprotectedUserAVUs(*SourceItemName, *TargetItemType, *TargetItemName);
    }

    # fail to prevent iRODS from also copying the protected metadata
    cut;
  }
}
