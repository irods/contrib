acPostProcForPut {
    if ($filePath like "*.jpg" || $filePath like "*.jpeg" || $filePath like "*.bmp" || 
        $filePath like "*.tif" || $filePath like "*.tiff" || $filePath like "*.rif" || 
        $filePath like "*.gif" || $filePath like "*.png"  || $filePath like "*.svg" || 
        $filePath like "*.xpm") {
        msiget_image_meta($filePath, *meta);
        msiString2KeyValPair(*meta, *meta_kvp);
        msiAssociateKeyValuePairsToObj(*meta_kvp, $objPath, "-d");
    }
} 

